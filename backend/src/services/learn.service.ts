import prisma from '../config/database';

// Seed some default learning content
export async function seedArticles() {
  const count = await prisma.article.count();
  if (count > 0) return;

  const articles = [
    {
      title: 'Mastering the Art of Pitching to Investors',
      description: 'Learn how to craft a compelling pitch that resonates with investors and secures funding for your startup.',
      type: 'ARTICLE',
      thumbnailUrl: 'https://images.unsplash.com/photo-1559136555-9303baea8ebd?w=400',
      duration: '5 min read',
      category: 'Fundraising',
      author: 'Dealance Team',
    },
    {
      title: 'Scaling Your Business: Strategies for Sustainable Growth',
      description: 'Explore proven strategies for scaling your business while maintaining quality and customer satisfaction.',
      type: 'VIDEO',
      contentUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      thumbnailUrl: 'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=400',
      duration: '12 min video',
      category: 'Growth',
      author: 'Growth Experts',
    },
    {
      title: 'Legal Essentials for Startups: Protecting Your IP',
      description: 'Understand the key legal considerations for startups, including how to protect your intellectual property.',
      type: 'GUIDE',
      thumbnailUrl: 'https://images.unsplash.com/photo-1589829545856-d10d557cf95f?w=400',
      duration: '8 min read',
      category: 'Legal',
      author: 'Legal Advisory',
    },
    {
      title: 'How to Validate Your Startup Idea in 7 Days',
      description: 'A step-by-step guide to quickly validate your business idea before investing significant time and money.',
      type: 'GUIDE',
      thumbnailUrl: 'https://images.unsplash.com/photo-1553877522-43269d4ea984?w=400',
      duration: '10 min read',
      category: 'Validation',
      author: 'Startup Academy',
    },
    {
      title: 'Understanding Venture Capital: From Seed to Series A',
      description: 'A comprehensive breakdown of venture capital stages, what investors look for, and how to prepare.',
      type: 'ARTICLE',
      thumbnailUrl: 'https://images.unsplash.com/photo-1579532537598-459ecdaf39cc?w=400',
      duration: '7 min read',
      category: 'Fundraising',
      author: 'VC Insights',
    },
    {
      title: 'Building a Strong Founding Team',
      description: 'Learn what investors look for in founding teams and how to assemble the right co-founders.',
      type: 'VIDEO',
      contentUrl: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      thumbnailUrl: 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=400',
      duration: '15 min video',
      category: 'Team Building',
      author: 'Founder Stories',
    },
    {
      title: 'Market Research on a Budget',
      description: 'Affordable tools and techniques to conduct effective market research for your startup.',
      type: 'CASE_STUDY',
      thumbnailUrl: 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=400',
      duration: '6 min read',
      category: 'Market Research',
      author: 'Research Hub',
    },
    {
      title: 'Digital Marketing for Early-Stage Startups',
      description: 'Cost-effective digital marketing strategies to build your brand and acquire your first 1000 users.',
      type: 'ARTICLE',
      thumbnailUrl: 'https://images.unsplash.com/photo-1432888622747-4eb9a8efeb07?w=400',
      duration: '9 min read',
      category: 'Marketing',
      author: 'Growth Team',
    },
  ];

  await prisma.article.createMany({ data: articles });
  console.log(`📚 Seeded ${articles.length} learning articles`);
}

export async function getArticles(filters?: {
  type?: string;
  category?: string;
  search?: string;
}) {
  const where: any = { published: true };

  if (filters?.type && filters.type !== 'All') {
    where.type = filters.type.toUpperCase();
  }

  if (filters?.category) {
    where.category = { contains: filters.category };
  }

  if (filters?.search) {
    where.OR = [
      { title: { contains: filters.search } },
      { description: { contains: filters.search } },
    ];
  }

  return prisma.article.findMany({
    where,
    orderBy: { createdAt: 'desc' },
  });
}

export async function getCategories() {
  const articles = await prisma.article.findMany({
    where: { published: true },
    select: { category: true },
    distinct: ['category'],
  });

  return articles
    .map((a) => a.category)
    .filter(Boolean);
}

export async function getArticleById(id: string) {
  const article = await prisma.article.findUnique({ where: { id } });
  if (!article) {
    throw Object.assign(new Error('Article not found'), { statusCode: 404 });
  }
  return article;
}
