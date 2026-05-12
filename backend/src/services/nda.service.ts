import prisma from '../config/database';

/**
 * Sign an NDA for an idea.
 */
export async function signNDA(ideaId: string, investorId: string, signatureText: string) {
  // Verify idea exists and requires NDA
  const idea = await prisma.idea.findFirst({
    where: { id: ideaId, status: 'SUBMITTED', visibility: 'NDA_REQUIRED' },
  });

  if (!idea) {
    throw Object.assign(new Error('Idea not found or does not require NDA'), { statusCode: 404 });
  }

  // Check if already signed
  const existing = await prisma.nDASignature.findUnique({
    where: { ideaId_investorId: { ideaId, investorId } },
  });

  if (existing) {
    return { message: 'NDA already signed', signature: existing };
  }

  // Create NDA signature
  const signature = await prisma.nDASignature.create({
    data: {
      ideaId,
      investorId,
      signatureText,
    },
  });

  // Notify the entrepreneur
  await prisma.notification.create({
    data: {
      userId: idea.userId,
      type: 'INVESTOR_VIEW',
      title: 'NDA Signed',
      message: `An investor has signed the NDA for your idea "${idea.companyName || idea.oneLiner || 'Untitled'}"`,
      data: JSON.stringify({ ideaId, investorId }),
    },
  });

  return { message: 'NDA signed successfully', signature };
}

/**
 * Check if investor has signed NDA for an idea.
 */
export async function checkNDA(ideaId: string, investorId: string) {
  const signature = await prisma.nDASignature.findUnique({
    where: { ideaId_investorId: { ideaId, investorId } },
  });

  return { signed: !!signature, signature };
}

/**
 * Invite an investor to an INVITE_ONLY idea (called by entrepreneur).
 */
export async function inviteInvestor(ideaId: string, entrepreneurId: string, investorId: string) {
  // Verify idea ownership
  const idea = await prisma.idea.findFirst({
    where: { id: ideaId, userId: entrepreneurId },
  });

  if (!idea) {
    throw Object.assign(new Error('Idea not found'), { statusCode: 404 });
  }

  // Check if already invited
  const existing = await prisma.ideaAccess.findUnique({
    where: { ideaId_investorId: { ideaId, investorId } },
  });

  if (existing) {
    return { message: 'Investor already invited', access: existing };
  }

  // Create access record
  const access = await prisma.ideaAccess.create({
    data: {
      ideaId,
      investorId,
      status: 'INVITED',
    },
  });

  // Notify investor
  await prisma.notification.create({
    data: {
      userId: investorId,
      type: 'INVESTOR_VIEW',
      title: 'New Deal Invitation',
      message: `You've been invited to view "${idea.companyName || idea.oneLiner || 'an idea'}"`,
      data: JSON.stringify({ ideaId }),
    },
  });

  return { message: 'Investor invited successfully', access };
}

/**
 * Get list of investors for directory (searchable).
 */
export async function getInvestorDirectory(search?: string) {
  const where: any = { role: 'INVESTOR' };

  if (search) {
    where.OR = [
      { name: { contains: search, mode: 'insensitive' } },
      { email: { contains: search, mode: 'insensitive' } },
      { bio: { contains: search, mode: 'insensitive' } },
    ];
  }

  return prisma.user.findMany({
    where,
    select: {
      id: true,
      name: true,
      email: true,
      avatar: true,
      bio: true,
      linkedIn: true,
      verified: true,
    },
    orderBy: { name: 'asc' },
    take: 50,
  });
}

/**
 * Get investors already invited to an idea.
 */
export async function getInvitedInvestors(ideaId: string, entrepreneurId: string) {
  // Verify ownership
  const idea = await prisma.idea.findFirst({
    where: { id: ideaId, userId: entrepreneurId },
  });

  if (!idea) {
    throw Object.assign(new Error('Idea not found'), { statusCode: 404 });
  }

  return prisma.ideaAccess.findMany({
    where: { ideaId },
    include: {
      investor: {
        select: { id: true, name: true, email: true, avatar: true },
      },
    },
    orderBy: { createdAt: 'desc' },
  });
}
