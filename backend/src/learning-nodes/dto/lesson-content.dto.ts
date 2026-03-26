// DTO definitions for 4 lesson types

export type LessonType = 'image_quiz' | 'image_gallery' | 'video' | 'text';

// === Image Quiz (flashcard swipe) ===
export interface ImageQuizSlide {
  imageUrl: string;
  question: string;
  options: Array<{ text: string; explanation: string }>; // 4 ABCD
  correctAnswer: number; // 0-3
  hint: string;
}

export interface ImageQuizLessonData {
  slides: ImageQuizSlide[];
}

// === Image Gallery ===
export interface GalleryImage {
  url: string;
  description: string;
}

export interface ImageGalleryLessonData {
  images: GalleryImage[];
}

// === Video ===
export interface VideoKeyPoint {
  title: string;
  description?: string;
  timestamp?: number; // seconds
}

export interface VideoLessonData {
  videoUrl: string;
  summary: string;
  keyPoints: VideoKeyPoint[];
  keywords: string[];
}

// === Text ===
export interface TextSection {
  title: string;
  content: string;
  richContent?: any; // Quill delta
}

export interface InlineQuiz {
  afterSectionIndex: number;
  question: string;
  options: Array<{ text: string; explanation: string }>;
  correctAnswer: number;
}

export interface TextLessonData {
  sections: TextSection[];
  inlineQuizzes: InlineQuiz[];
  summary: string;
  learningObjectives: string[];
}

// === End Quiz (shared) ===
export interface EndQuizQuestion {
  question: string;
  options: Array<{ text: string; explanation: string }>;
  correctAnswer: number;
  logicTypes?: string[];
  competencyMix?: Record<string, number>;
}

export interface EndQuizData {
  questions: EndQuizQuestion[];
  passingScore: number; // default 70
}

// === Combined DTO ===
export interface UpdateLessonContentDto {
  lessonType: LessonType;
  lessonData: ImageQuizLessonData | ImageGalleryLessonData | VideoLessonData | TextLessonData;
  endQuiz: EndQuizData;
  title?: string;
  description?: string;
}

export interface SubmitEndQuizDto {
  answers: number[]; // array of selected option indices
  responseTimesMs?: number[]; // per-question response time from client
}

export interface EndQuizResultDto {
  passed: boolean;
  score: number; // percentage
  totalQuestions: number;
  correctCount: number;
  results: Array<{
    questionIndex: number;
    question: string;
    selectedAnswer: number;
    correctAnswer: number;
    isCorrect: boolean;
    explanation: string;
  }>;
}

// Validation helpers
export function validateLessonContent(
  lessonType: LessonType,
  lessonData: any,
): { valid: boolean; errors: string[] } {
  const errors: string[] = [];

  if (!lessonType) {
    errors.push('lessonType is required');
    return { valid: false, errors };
  }

  if (!lessonData) {
    errors.push('lessonData is required');
    return { valid: false, errors };
  }

  switch (lessonType) {
    case 'image_quiz':
      if (!lessonData.slides || !Array.isArray(lessonData.slides) || lessonData.slides.length === 0) {
        errors.push('image_quiz requires at least 1 slide');
      } else {
        lessonData.slides.forEach((slide: any, i: number) => {
          if (!slide.imageUrl) errors.push(`Slide ${i + 1}: imageUrl is required`);
          if (!slide.question) errors.push(`Slide ${i + 1}: question is required`);
          if (!slide.options || slide.options.length !== 4) errors.push(`Slide ${i + 1}: exactly 4 options required`);
          if (slide.correctAnswer === undefined || slide.correctAnswer < 0 || slide.correctAnswer > 3) {
            errors.push(`Slide ${i + 1}: correctAnswer must be 0-3`);
          }
        });
      }
      break;

    case 'image_gallery':
      if (!lessonData.images || !Array.isArray(lessonData.images) || lessonData.images.length === 0) {
        errors.push('image_gallery requires at least 1 image');
      } else {
        lessonData.images.forEach((img: any, i: number) => {
          if (!img.url) errors.push(`Image ${i + 1}: url is required`);
          if (!img.description) errors.push(`Image ${i + 1}: description is required`);
        });
      }
      break;

    case 'video':
      if (!lessonData.videoUrl) errors.push('videoUrl is required');
      if (!lessonData.summary) errors.push('summary is required');
      if (!lessonData.keyPoints || !Array.isArray(lessonData.keyPoints) || lessonData.keyPoints.length === 0) {
        errors.push('At least 1 key point is required');
      }
      break;

    case 'text':
      if (!lessonData.sections || !Array.isArray(lessonData.sections) || lessonData.sections.length === 0) {
        errors.push('At least 1 section is required');
      } else {
        lessonData.sections.forEach((sec: any, i: number) => {
          if (!sec.title) errors.push(`Section ${i + 1}: title is required`);
          if (!sec.content) errors.push(`Section ${i + 1}: content is required`);
        });
      }
      if (!lessonData.summary) errors.push('summary is required');
      break;

    default:
      errors.push(`Unknown lessonType: ${lessonType}`);
  }

  return { valid: errors.length === 0, errors };
}

export function validateEndQuiz(endQuiz: any): { valid: boolean; errors: string[] } {
  const errors: string[] = [];

  if (!endQuiz || !endQuiz.questions) {
    errors.push('endQuiz with questions is required');
    return { valid: false, errors };
  }

  if (!Array.isArray(endQuiz.questions) || endQuiz.questions.length < 5) {
    errors.push('endQuiz requires at least 5 questions');
    return { valid: false, errors };
  }

  if (endQuiz.questions.length > 7) {
    errors.push('endQuiz allows at most 7 questions');
    return { valid: false, errors };
  }

  endQuiz.questions.forEach((q: any, i: number) => {
    if (!q.question) errors.push(`Quiz question ${i + 1}: question text is required`);
    if (!q.options || q.options.length !== 4) errors.push(`Quiz question ${i + 1}: exactly 4 options required`);
    if (q.correctAnswer === undefined || q.correctAnswer < 0 || q.correctAnswer > 3) {
      errors.push(`Quiz question ${i + 1}: correctAnswer must be 0-3`);
    }
    if (q.logicTypes !== undefined) {
      if (!Array.isArray(q.logicTypes) || q.logicTypes.some((x: unknown) => typeof x !== 'string' || !x.trim())) {
        errors.push(`Quiz question ${i + 1}: logicTypes must be an array of non-empty strings`);
      }
    }
    if (q.competencyMix !== undefined) {
      if (typeof q.competencyMix !== 'object' || q.competencyMix === null || Array.isArray(q.competencyMix)) {
        errors.push(`Quiz question ${i + 1}: competencyMix must be an object`);
      } else {
        const entries = Object.entries(q.competencyMix as Record<string, unknown>);
        if (entries.length === 0) {
          errors.push(`Quiz question ${i + 1}: competencyMix must have at least 1 key`);
        } else {
          let sum = 0;
          for (const [k, v] of entries) {
            if (!k.trim()) {
              errors.push(`Quiz question ${i + 1}: competencyMix key cannot be empty`);
              continue;
            }
            if (typeof v !== 'number' || Number.isNaN(v)) {
              errors.push(`Quiz question ${i + 1}: competencyMix[${k}] must be a number`);
              continue;
            }
            if (v < 0 || v > 1) {
              errors.push(`Quiz question ${i + 1}: competencyMix[${k}] must be in [0, 1]`);
            }
            sum += v;
          }
          if (sum < 0.95 || sum > 1.05) {
            errors.push(`Quiz question ${i + 1}: competencyMix weights must sum approximately to 1`);
          }
        }
      }
    }
  });

  return { valid: errors.length === 0, errors };
}
