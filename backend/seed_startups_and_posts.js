const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const user = await prisma.user.findFirst({
    where: { email: { contains: 'aravindpunyamantula630' } }
  });

  if (!user) {
    console.error("User not found!");
    return;
  }

  // Define two startups
  const startup1 = await prisma.idea.create({
    data: {
      userId: user.id,
      businessType: 'STARTUP',
      companyName: 'QuantumLeap AI',
      tagline: 'Next-gen quantum computing for AI models.',
      logoUrl: 'https://images.unsplash.com/photo-1633412802994-5c058f151b66?auto=format&fit=crop&w=200&q=80',
      cardUrl: 'https://images.unsplash.com/photo-1633412802994-5c058f151b66?auto=format&fit=crop&w=800&q=80',
      oneLiner: 'We accelerate AI model training by 100x using simulated quantum processors.',
      detailedProblem: 'Training large language models takes months and millions of dollars in compute resources, limiting AI innovation to big tech.',
      solution: 'A cloud-based quantum-simulated computing environment that optimizes matrix multiplication at the hardware level.',
      evidenceUrl: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
      pitchDeckUrl: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
      videoPitchUrl: 'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
      productDescription: 'QuantumLeap AI provides a PyTorch compatible API that magically routes compute to our quantum simulators.',
      industry: 'DeepTech / AI',
      subDomains: 'Hardware, Machine Learning',
      businessModel: 'Usage-based pricing per compute hour.',
      targetGeography: 'Global',
      stage: 'Seed',
      currentCustomers: '3 academic partnerships and 1 enterprise pilot.',
      revenue: '$0',
      growthRate: 'N/A',
      dailyActiveUsers: 10,
      currentValuation: '$8M',
      fundingAmount: '$1.5M',
      fundingType: 'SAFE',
      equityOffered: '15%',
      useOfFunds: '70% R&D, 30% Go-To-Market',
      founderName: 'Aravind Punyamantula',
      founderEmail: user.email,
      founderPhone: '+1-555-0101',
      teamMembers: 'Aravind (CEO) - PhD in Quantum Physics. Alex (CTO) - Ex-OpenAI researcher.',
      status: 'PUBLISHED',
      currentStep: 5,
      visibility: 'PUBLIC'
    }
  });

  const startup2 = await prisma.idea.create({
    data: {
      userId: user.id,
      businessType: 'STARTUP',
      companyName: 'GreenChain Logistics',
      tagline: 'Sustainable supply chain tracking.',
      logoUrl: 'https://images.unsplash.com/photo-1586528116311-ad8ed7c508c0?auto=format&fit=crop&w=200&q=80',
      cardUrl: 'https://images.unsplash.com/photo-1586528116311-ad8ed7c508c0?auto=format&fit=crop&w=800&q=80',
      oneLiner: 'End-to-end carbon footprint tracking for global shipping routes.',
      detailedProblem: 'Companies cannot accurately measure or report the Scope 3 emissions of their complex supply chains.',
      solution: 'An IoT and blockchain integrated platform that measures emissions at every handoff point in real-time.',
      evidenceUrl: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
      pitchDeckUrl: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
      videoPitchUrl: 'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      productDescription: 'Integrates with major shipping lines to provide a single dashboard for carbon accounting.',
      industry: 'Logistics / CleanTech',
      subDomains: 'Supply Chain, Sustainability',
      businessModel: 'SaaS Subscription + API usage fees',
      targetGeography: 'North America, Europe',
      stage: 'Series A',
      currentCustomers: '12 enterprise clients including 2 Fortune 500 retailers.',
      revenue: '$50k MRR',
      growthRate: '15% MoM',
      dailyActiveUsers: 500,
      currentValuation: '$20M',
      fundingAmount: '$5M',
      fundingType: 'Equity',
      equityOffered: '20%',
      useOfFunds: '50% Sales & Marketing, 30% Product Expansion, 20% Operations',
      founderName: 'Aravind Punyamantula',
      founderEmail: user.email,
      founderPhone: '+1-555-0202',
      teamMembers: 'Aravind (CEO) - 15 yrs in logistics. Maria (COO) - Supply chain expert.',
      status: 'PUBLISHED',
      currentStep: 5,
      visibility: 'PUBLIC'
    }
  });

  // Define media array with photo, video, and pdf
  const mediaUrls = JSON.stringify([
    'https://images.unsplash.com/photo-1633412802994-5c058f151b66?auto=format&fit=crop&w=800&q=80', // Photo
    'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4', // Video
    'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf' // PDF
  ]);

  const post1 = await prisma.post.create({
    data: {
      userId: user.id,
      startupId: startup1.id,
      content: '🚀 Excited to announce the launch of QuantumLeap AI! We are revolutionizing model training with quantum simulation. Check out our pitch deck, demo video, and architecture photo attached.',
      mediaUrls: mediaUrls,
    }
  });

  const post2 = await prisma.post.create({
    data: {
      userId: user.id,
      startupId: startup2.id,
      content: '🌍 Supply chain sustainability is no longer optional. GreenChain Logistics is proud to hit $50k MRR helping Fortune 500s track their carbon footprints! Here are our metrics, demo, and latest report.',
      mediaUrls: mediaUrls,
    }
  });

  console.log("Successfully created startups and posts!");
  console.log("Startup 1 ID:", startup1.id);
  console.log("Post 1 ID:", post1.id);
  console.log("Startup 2 ID:", startup2.id);
  console.log("Post 2 ID:", post2.id);
}

main().catch(console.error).finally(() => prisma.$disconnect());
