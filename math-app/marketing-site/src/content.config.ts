import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';

const blog = defineCollection({
  loader: glob({ pattern: '**/*.{md,mdx}', base: './src/content/blog' }),
  schema: z.object({
    title: z.string(),
    description: z.string(),
    publishedTime: z.string().datetime(),
    modifiedTime: z.string().datetime().optional(),
    author: z.string().default('HocVui'),
    tags: z.array(z.string()).default([]),
    targetKeyword: z.string(),
    heroImage: z.string().optional(),
    relatedLessons: z
      .array(
        z.object({
          subject: z.string(),
          grade: z.number().int().min(1).max(12),
        }),
      )
      .default([]),
  }),
});

const blogEn = defineCollection({
  loader: glob({ pattern: '**/*.{md,mdx}', base: './src/content/blog-en' }),
  schema: z.object({
    title: z.string(),
    description: z.string(),
    publishedTime: z.string().datetime(),
    modifiedTime: z.string().datetime().optional(),
    author: z.string().default('HocVui'),
    tags: z.array(z.string()).default([]),
    targetKeyword: z.string(),
    heroImage: z.string().optional(),
    relatedLessons: z
      .array(
        z.object({
          subject: z.string(),
          grade: z.number().int().min(1).max(12),
        }),
      )
      .default([]),
  }),
});

export const collections = { blog, 'blog-en': blogEn };
