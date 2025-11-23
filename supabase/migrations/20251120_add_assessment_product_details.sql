-- ===============================================
-- ADD ASSESSMENT PRODUCT DETAILS AND RESPONSES
-- Date: 2025-11-20
-- ===============================================

-- Add product detail columns and question response columns
ALTER TABLE public.assessment_sessions
  ADD COLUMN IF NOT EXISTS product_name TEXT,
  ADD COLUMN IF NOT EXISTS product_description TEXT,
  ADD COLUMN IF NOT EXISTS business_model TEXT,
  ADD COLUMN IF NOT EXISTS key_features TEXT,
  ADD COLUMN IF NOT EXISTS ideal_customer_description TEXT,
  ADD COLUMN IF NOT EXISTS customer_count TEXT,
  ADD COLUMN IF NOT EXISTS distinguishing_feature TEXT,
  ADD COLUMN IF NOT EXISTS q1_response INTEGER CHECK (q1_response >= 1 AND q1_response <= 4),
  ADD COLUMN IF NOT EXISTS q2_response INTEGER CHECK (q2_response >= 1 AND q2_response <= 4),
  ADD COLUMN IF NOT EXISTS q3_response INTEGER CHECK (q3_response >= 1 AND q3_response <= 4),
  ADD COLUMN IF NOT EXISTS q4_response INTEGER CHECK (q4_response >= 1 AND q4_response <= 4),
  ADD COLUMN IF NOT EXISTS q5_response INTEGER CHECK (q5_response >= 1 AND q5_response <= 4),
  ADD COLUMN IF NOT EXISTS q6_response INTEGER CHECK (q6_response >= 1 AND q6_response <= 4),
  ADD COLUMN IF NOT EXISTS q7_response INTEGER CHECK (q7_response >= 1 AND q7_response <= 4),
  ADD COLUMN IF NOT EXISTS q8_response INTEGER CHECK (q8_response >= 1 AND q8_response <= 4),
  ADD COLUMN IF NOT EXISTS q9_response INTEGER CHECK (q9_response >= 1 AND q9_response <= 4),
  ADD COLUMN IF NOT EXISTS q10_response INTEGER CHECK (q10_response >= 1 AND q10_response <= 4),
  ADD COLUMN IF NOT EXISTS q11_response INTEGER CHECK (q11_response >= 1 AND q11_response <= 4),
  ADD COLUMN IF NOT EXISTS q12_response INTEGER CHECK (q12_response >= 1 AND q12_response <= 4),
  ADD COLUMN IF NOT EXISTS q13_response INTEGER CHECK (q13_response >= 1 AND q13_response <= 4),
  ADD COLUMN IF NOT EXISTS q14_response INTEGER CHECK (q14_response >= 1 AND q14_response <= 4);

-- Add comments for documentation
COMMENT ON COLUMN public.assessment_sessions.product_name IS
  'Product or company name from assessment product input form';

COMMENT ON COLUMN public.assessment_sessions.product_description IS
  'Full product description explaining what the product does and who it serves';

COMMENT ON COLUMN public.assessment_sessions.business_model IS
  'Business model type (e.g., "B2B Subscription", "B2B One-time")';

COMMENT ON COLUMN public.assessment_sessions.key_features IS
  'Key product features that differentiate from competitors';

COMMENT ON COLUMN public.assessment_sessions.ideal_customer_description IS
  'Description of ideal target customer/buyer';

COMMENT ON COLUMN public.assessment_sessions.customer_count IS
  'Current customer base size or range';

COMMENT ON COLUMN public.assessment_sessions.distinguishing_feature IS
  'Primary feature that makes this product unique';

COMMENT ON COLUMN public.assessment_sessions.q1_response IS
  'Q1: I can name the exact three pain points that cost my buyers the most money annually (1-4 scale)';

COMMENT ON COLUMN public.assessment_sessions.q2_response IS
  'Q2: I know the specific job titles and departments involved in evaluating my product (1-4 scale)';

COMMENT ON COLUMN public.assessment_sessions.q3_response IS
  'Q3: I can describe my buyer''s current process for solving this problem without my product (1-4 scale)';

COMMENT ON COLUMN public.assessment_sessions.q4_response IS
  'Q4: I understand what metrics my buyers use to measure success in their role (1-4 scale)';

COMMENT ON COLUMN public.assessment_sessions.q5_response IS
  'Q5: I can explain my technical architecture in terms of business outcomes (1-4 scale)';

COMMENT ON COLUMN public.assessment_sessions.q6_response IS
  'Q6: I have quantified the ROI/cost savings my product delivers (1-4 scale)';

COMMENT ON COLUMN public.assessment_sessions.q7_response IS
  'Q7: I can articulate our competitive advantages in business terms (1-4 scale)';

COMMENT ON COLUMN public.assessment_sessions.q8_response IS
  'Q8: I can explain my API architecture to a CFO in terms of cost savings and risk reduction (1-4 scale)';

COMMENT ON COLUMN public.assessment_sessions.q9_response IS
  'Q9: I have prepared responses to common buyer objections (1-4 scale)';

COMMENT ON COLUMN public.assessment_sessions.q10_response IS
  'Q10: I can map our features to specific business problems and costs (1-4 scale)';

COMMENT ON COLUMN public.assessment_sessions.q11_response IS
  'Q11: I understand the buying process and timeline in my target market (1-4 scale)';

COMMENT ON COLUMN public.assessment_sessions.q12_response IS
  'Q12: I have case studies or proof points demonstrating measurable business value (1-4 scale)';

COMMENT ON COLUMN public.assessment_sessions.q13_response IS
  'Q13: I can identify buying signals and know when a prospect is ready to purchase (1-4 scale)';

COMMENT ON COLUMN public.assessment_sessions.q14_response IS
  'Q14: I have a systematic process for translating technical capabilities into buyer language (1-4 scale)';

-- Create indexes for analytics queries
CREATE INDEX IF NOT EXISTS idx_assessment_sessions_product_name ON public.assessment_sessions(product_name);
CREATE INDEX IF NOT EXISTS idx_assessment_sessions_q1_response ON public.assessment_sessions(q1_response);
CREATE INDEX IF NOT EXISTS idx_assessment_sessions_q2_response ON public.assessment_sessions(q2_response);
CREATE INDEX IF NOT EXISTS idx_assessment_sessions_q3_response ON public.assessment_sessions(q3_response);
CREATE INDEX IF NOT EXISTS idx_assessment_sessions_q4_response ON public.assessment_sessions(q4_response);