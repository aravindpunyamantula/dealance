import prisma from '../config/database';
import groq from '../config/groq';
import { GetObjectCommand } from '@aws-sdk/client-s3';
import { s3Client, BUCKET } from '../config/s3';

export async function triggerAnalysis(ideaId: string, userId: string) {
  // Get the idea with ALL fields
  const idea = await prisma.idea.findFirst({
    where: { id: ideaId, userId },
  });

  if (!idea) {
    throw Object.assign(new Error('Idea not found'), { statusCode: 404 });
  }

  // Check if there's already a pending/processing report
  const existingReport = await prisma.aIReport.findFirst({
    where: {
      ideaId,
      status: { in: ['PENDING', 'PROCESSING'] },
    },
  });

  if (existingReport) {
    return existingReport;
  }

  // Create a pending report
  const report = await prisma.aIReport.create({
    data: {
      ideaId,
      userId,
      status: 'PROCESSING',
    },
  });

  // Run analysis asynchronously
  processAnalysis(report.id, idea).catch((err) => {
    console.error('AI Analysis failed:', err);
    prisma.aIReport.update({
      where: { id: report.id },
      data: { status: 'FAILED', errorMessage: err.message },
    }).catch(console.error);
  });

  return report;
}

// Try to extract text content from an S3 file (for PDFs/text docs)
async function extractFileContent(fileUrl: string | null | undefined): Promise<string | null> {
  if (!fileUrl) return null;

  try {
    // Extract S3 key from the URL
    const urlParts = fileUrl.split('.amazonaws.com/');
    if (urlParts.length < 2) return `[File uploaded: ${fileUrl}]`;
    const key = urlParts[1];

    const response = await s3Client.send(new GetObjectCommand({
      Bucket: BUCKET,
      Key: key,
    }));

    // Only try to read text-based files, skip images/videos
    const contentType = response.ContentType || '';
    if (contentType.includes('image') || contentType.includes('video')) {
      return `[Media file uploaded: ${key.split('/').pop()}]`;
    }

    // Read the body as text (works for text/plain, CSV, etc.)
    if (contentType.includes('text') || contentType.includes('json') || contentType.includes('csv')) {
      const body = await response.Body?.transformToString();
      if (body && body.length < 10000) {
        return body;
      }
      return body ? body.substring(0, 10000) + '\n[...truncated]' : null;
    }

    // For PDFs, PPTs — we can't extract text directly, but we note them
    const fileName = key.split('/').pop() || 'unknown';
    const size = response.ContentLength ? `(${(response.ContentLength / 1024).toFixed(0)}KB)` : '';
    return `[Document uploaded: ${fileName} ${size} — type: ${contentType}]`;
  } catch (err: any) {
    console.warn(`Could not read file ${fileUrl}:`, err.message);
    return `[File reference: ${fileUrl}]`;
  }
}

async function processAnalysis(reportId: string, idea: any) {
  console.log(`🤖 Starting AI analysis for idea: ${idea.companyName || idea.id}`);

  // Try to extract file contents
  const [evidenceContent, pitchDeckContent, videoPitchInfo] = await Promise.all([
    extractFileContent(idea.evidenceUrl),
    extractFileContent(idea.pitchDeckUrl),
    extractFileContent(idea.videoPitchUrl),
  ]);

  const prompt = buildAnalysisPrompt(idea, {
    evidenceContent,
    pitchDeckContent,
    videoPitchInfo,
  });

  try {
    const response = await groq.chat.completions.create({
      model: 'llama-3.3-70b-versatile',
      messages: [
        {
          role: 'system',
          content: 'You are a world-class business analyst and venture capital advisor with 20 years of experience evaluating startups. You MUST respond ONLY with valid JSON. No markdown, no code fences — just the raw JSON object.',
        },
        {
          role: 'user',
          content: prompt,
        },
      ],
      temperature: 0.3,
      max_tokens: 4096,
      response_format: { type: 'json_object' },
    });

    const text = response.choices?.[0]?.message?.content || '';
    console.log(`✅ AI response received (${text.length} chars)`);

    let parsedReport: any;

    try {
      parsedReport = JSON.parse(text);
    } catch {
      console.warn('⚠️ Failed to parse AI response as JSON, wrapping in basic structure');
      parsedReport = {
        viabilityScore: 50,
        executiveSummary: text,
        existingCompetitors: [],
        marketAnalysis: { marketSize: 'Unable to determine', growthRate: 'N/A', targetDemographic: 'N/A' },
        strengthsAndWeaknesses: { strengths: [], weaknesses: [] },
        successFactors: [],
        risks: [],
        recommendations: [text],
        similarSuccessStories: [],
      };
    }

    const viabilityScore = parsedReport.viabilityScore || 50;

    await prisma.aIReport.update({
      where: { id: reportId },
      data: {
        status: 'COMPLETE',
        viabilityScore,
        report: JSON.stringify(parsedReport),
      },
    });

    // Create notification
    await prisma.notification.create({
      data: {
        userId: idea.userId,
        type: 'AI_REPORT',
        title: 'AI Analysis Complete',
        message: `Your idea "${idea.companyName || idea.oneLiner || 'Untitled'}" scored ${viabilityScore}/100`,
        data: JSON.stringify({ ideaId: idea.id, reportId }),
      },
    });

    console.log(`📊 AI report saved with score: ${viabilityScore}/100`);
  } catch (err: any) {
    const errorMsg = err.message || 'Unknown AI error';
    console.error(`❌ AI Analysis failed for idea ${idea.id}:`, errorMsg);

    let userMessage = errorMsg;
    if (errorMsg.includes('429') || errorMsg.includes('rate_limit') || errorMsg.includes('quota')) {
      userMessage = 'AI rate limit reached. Please wait a minute and try again.';
    } else if (errorMsg.includes('timed out') || errorMsg.includes('timeout')) {
      userMessage = 'AI analysis timed out. Please try again.';
    }

    await prisma.aIReport.update({
      where: { id: reportId },
      data: { status: 'FAILED', errorMessage: userMessage },
    });
    throw err;
  }
}

function buildAnalysisPrompt(idea: any, files: {
  evidenceContent?: string | null;
  pitchDeckContent?: string | null;
  videoPitchInfo?: string | null;
}): string {

  // Parse JSON fields safely
  let useOfFunds = idea.useOfFunds || 'Not specified';
  let teamMembers = 'Not specified';
  try { if (idea.useOfFunds) useOfFunds = JSON.parse(idea.useOfFunds); } catch {}
  try { if (idea.teamMembers) teamMembers = JSON.parse(idea.teamMembers); } catch {}

  return `Analyze the following business idea with EXTREME thoroughness. Use ALL the data provided — every single detail matters for the analysis.

═══════════════════════════════════════════
STEP 1: COMPANY & PROBLEM-SOLUTION
═══════════════════════════════════════════
• Company Name: ${idea.companyName || 'Not specified'}
• Tagline: ${idea.tagline || 'Not specified'}
• Business Type: ${idea.businessType || 'STARTUP'}
• One-Liner Problem: ${idea.oneLiner || 'Not specified'}
• Detailed Problem Description: ${idea.detailedProblem || 'Not specified'}
• Product / Solution: ${idea.solution || idea.productDescription || 'Not specified'}
• Logo: ${idea.logoUrl ? 'Provided' : 'Not uploaded'}
• Business Card: ${idea.cardUrl ? 'Provided' : 'Not uploaded'}

═══════════════════════════════════════════
STEP 2: MARKET & BUSINESS MODEL
═══════════════════════════════════════════
• Industry / Sector: ${idea.industry || 'Not specified'}
• Sub-Domains: ${idea.subDomains || 'Not specified'}
• Business Model: ${idea.businessModel || 'Not specified'}
• Target Geography: ${idea.targetGeography || 'Not specified'}
• Current Stage: ${idea.stage || 'Not specified'}

═══════════════════════════════════════════
STEP 3: TRACTION & KPIs
═══════════════════════════════════════════
• Current Customers: ${idea.currentCustomers || 'Not specified'}
• Revenue (MRR/ARR): ${idea.revenue || 'Not specified'}
• Growth Rate: ${idea.growthRate || 'Not specified'}
• Daily Active Users: ${idea.dailyActiveUsers || 'Not specified'}

═══════════════════════════════════════════
STEP 4: FINANCIAL & FUNDING
═══════════════════════════════════════════
• Current Valuation: ${idea.currentValuation || 'Not specified'}
• Funding Amount Requested: ${idea.fundingAmount || 'Not specified'}
• Funding Type: ${idea.fundingType || 'Not specified'}
• Equity Offered: ${idea.equityOffered || 'Not specified'}
• Use of Funds: ${typeof useOfFunds === 'string' ? useOfFunds : JSON.stringify(useOfFunds)}

═══════════════════════════════════════════
STEP 5: TEAM
═══════════════════════════════════════════
• Founder Name: ${idea.founderName || 'Not specified'}
• Founder Email: ${idea.founderEmail || 'Not specified'}
• Team Members: ${typeof teamMembers === 'string' ? teamMembers : JSON.stringify(teamMembers)}

═══════════════════════════════════════════
UPLOADED DOCUMENTS & FILES
═══════════════════════════════════════════
• Evidence of Problem: ${files.evidenceContent || (idea.evidenceUrl ? `Uploaded at: ${idea.evidenceUrl}` : 'Not uploaded')}
• Pitch Deck: ${files.pitchDeckContent || (idea.pitchDeckUrl ? `Uploaded at: ${idea.pitchDeckUrl}` : 'Not uploaded')}
• Video Pitch: ${files.videoPitchInfo || (idea.videoPitchUrl ? `Uploaded at: ${idea.videoPitchUrl}` : 'Not uploaded')}

═══════════════════════════════════════════
STATUS
═══════════════════════════════════════════
• Submission Status: ${idea.status}
• Current Step: ${idea.currentStep}/5
• Created: ${idea.createdAt}
• Last Updated: ${idea.updatedAt}

═══════════════════════════════════════════
ANALYSIS REQUIREMENTS
═══════════════════════════════════════════
Based on ALL the above data:
1. Search your knowledge for existing similar products, services, and companies.
2. Analyze the competitive landscape — name specific real competitors.
3. Estimate market size (TAM/SAM/SOM) and growth potential.
4. Evaluate the team's ability to execute (if team info provided).
5. Assess financial viability and funding ask reasonableness.
6. Identify key risks and critical challenges.
7. Provide specific, actionable recommendations.
8. Rate investment readiness honestly.

Respond with JSON in this exact structure:
{
  "viabilityScore": <number 1-100>,
  "executiveSummary": "<3-4 paragraph comprehensive summary covering problem, solution, market fit, and overall assessment>",
  "existingCompetitors": [
    {
      "name": "<real competitor name>",
      "similarity": <percentage 1-100>,
      "url": "<actual website URL>",
      "description": "<how they compare, what they do differently>"
    }
  ],
  "marketAnalysis": {
    "marketSize": "<estimated TAM with dollar figure>",
    "growthRate": "<estimated CAGR percentage>",
    "targetDemographic": "<specific customer segments>",
    "marketTrends": "<2-3 key relevant trends>"
  },
  "strengthsAndWeaknesses": {
    "strengths": ["<specific strength based on provided data>"],
    "weaknesses": ["<specific weakness or gap identified>"]
  },
  "successFactors": ["<critical factor for success>"],
  "risks": ["<specific risk with explanation>"],
  "recommendations": ["<specific actionable recommendation>"],
  "similarSuccessStories": [
    {
      "company": "<real company name>",
      "outcome": "<what happened — funding, exit, growth>",
      "relevance": "<why this is relevant to this idea>"
    }
  ],
  "uniquenessScore": <number 1-100>,
  "investmentReadiness": "<READY | NEEDS_WORK | NOT_READY>",
  "estimatedTimeToMarket": "<realistic time estimate>",
  "suggestedPivots": ["<alternative direction if current approach is weak>"],
  "teamAssessment": "<assessment of team capability based on provided info>",
  "financialAnalysis": "<assessment of funding ask, valuation, and use of funds>"
}`;
}

export async function getReport(ideaId: string, userId: string) {
  const report = await prisma.aIReport.findFirst({
    where: { ideaId, userId },
    orderBy: { createdAt: 'desc' },
  });

  if (!report) {
    throw Object.assign(new Error('No report found for this idea'), { statusCode: 404 });
  }

  let parsedReport = null;
  if (report.report) {
    try {
      parsedReport = JSON.parse(report.report);
    } catch {
      parsedReport = { raw: report.report };
    }
  }

  return {
    ...report,
    parsedReport,
  };
}

export async function getReportStatus(ideaId: string, userId: string) {
  const report = await prisma.aIReport.findFirst({
    where: { ideaId, userId },
    orderBy: { createdAt: 'desc' },
    select: { id: true, status: true, viabilityScore: true, createdAt: true, updatedAt: true },
  });

  return report;
}

// In-memory cache for investor AI reviews: Map<ideaId, { data: string, expiresAt: number }>
const investorReviewCache = new Map<string, { data: string, expiresAt: number }>();
const CACHE_TTL_MS = 60 * 60 * 1000; // 1 hour

export async function getInvestorAIReview(ideaId: string): Promise<string> {
  // Check cache
  const cached = investorReviewCache.get(ideaId);
  if (cached && Date.now() < cached.expiresAt) {
    return cached.data;
  }

  // Fetch idea
  const idea = await prisma.idea.findUnique({
    where: { id: ideaId },
  });

  if (!idea) {
    throw Object.assign(new Error('Idea not found'), { statusCode: 404 });
  }

  // Construct detailed prompt for investor
  const prompt = `You are a world-class venture capital analyst. Analyze the following startup strictly from an investor's perspective. 
Provide a detailed report formatting your response in Markdown. Use bolding, lists, and structure to make it clear.
Include the following sections clearly:
1. Chance of Success (Give a realistic percentage and a brief explanation)
2. Improvements (Areas the startup needs to focus on to succeed)
3. Future Scope (Scalability, TAM, growth potential)
4. Pros and Cons for Investing (A balanced list)

STARTUP DATA:
Company Name: ${idea.companyName || 'Not specified'}
Tagline: ${idea.tagline || 'Not specified'}
Problem: ${idea.detailedProblem || idea.oneLiner || 'Not specified'}
Solution: ${idea.solution || idea.productDescription || 'Not specified'}
Market/Industry: ${idea.industry || 'Not specified'} - ${idea.subDomains || 'Not specified'}
Traction (Customers/Revenue): Customers: ${idea.currentCustomers || 'N/A'}, Revenue: ${idea.revenue || 'N/A'}
Funding Ask: ${idea.fundingAmount || 'N/A'} at ${idea.currentValuation || 'N/A'} valuation
Team: ${idea.teamMembers || 'N/A'}

Provide ONLY the markdown report.`;

  // Call groq
  const completion = await groq.chat.completions.create({
    messages: [{ role: 'user', content: prompt }],
    model: 'llama-3.3-70b-versatile',
    temperature: 0.7,
    max_tokens: 2000,
  });

  const responseText = completion.choices[0]?.message?.content || 'Failed to generate review.';

  // Cache the result
  investorReviewCache.set(ideaId, {
    data: responseText,
    expiresAt: Date.now() + CACHE_TTL_MS,
  });

  return responseText;
}
