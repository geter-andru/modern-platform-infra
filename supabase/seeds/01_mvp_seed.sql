-- ============================================
-- MVP SEED FILE
-- Date: October 3, 2025
-- Purpose: Enable testing of 4 core features with minimal but functional data
-- Scope: ICP Tool, Resources Library, Assessment, Cost Calculator
-- ============================================

-- ============================================
-- MIGRATION LOGGING
-- ============================================

-- Ensure migration_name is unique so upsert works
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint c
    JOIN pg_class t ON t.oid = c.conrelid
    JOIN pg_namespace n ON n.oid = t.relnamespace
    WHERE c.conname = 'migration_log_migration_name_key'
      AND n.nspname = 'public'
      AND t.relname = 'migration_log'
  ) THEN
    -- Deduplicate migration_log entries
    WITH dups AS (
      SELECT id,
             ROW_NUMBER() OVER (PARTITION BY migration_name ORDER BY executed_at DESC NULLS LAST, id DESC) AS rn
      FROM public.migration_log
    )
    DELETE FROM public.migration_log m
    USING dups
    WHERE m.id = dups.id AND dups.rn > 1;

    ALTER TABLE public.migration_log
      ADD CONSTRAINT migration_log_migration_name_key UNIQUE (migration_name);
  END IF;
END $$;

-- Record start of MVP seeding (idempotent)
INSERT INTO public.migration_log (migration_name, executed_at, status, details)
VALUES ('01_mvp_seed', now(), 'started', 'Beginning MVP database seeding for 4 core features')
ON CONFLICT (migration_name) DO UPDATE SET
  executed_at = NOW(),
  status = 'started',
  details = 'Re-running MVP database seeding for 4 core features';

-- ============================================
-- PART 1: CORE RESOURCES (4 Resources Only)
-- ============================================
-- Purpose: Enable Resources Library testing
-- Customer ID: 'global' (accessible to all users)

-- Ensure unique constraint exists for idempotent seeding
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint c
    JOIN pg_class t ON t.oid = c.conrelid
    JOIN pg_namespace n ON n.oid = t.relnamespace
    WHERE c.conname = 'resources_unique_global'
      AND n.nspname = 'public'
      AND t.relname = 'resources'
  ) THEN
    -- Optional dedup in case of historical duplicates
    WITH dups AS (
      SELECT id,
             ROW_NUMBER() OVER (PARTITION BY customer_id, title ORDER BY updated_at DESC NULLS LAST, created_at DESC NULLS LAST, id DESC) AS rn
      FROM public.resources
    )
    DELETE FROM public.resources r
    USING dups
    WHERE r.id = dups.id AND dups.rn > 1;

    ALTER TABLE public.resources
      ADD CONSTRAINT resources_unique_global UNIQUE (customer_id, title);
  END IF;
END $$;

INSERT INTO resources (
  customer_id, 
  tier, 
  category, 
  title, 
  description,
  content, 
  generation_status, 
  export_formats,
  access_count,
  created_at,
  updated_at
) VALUES

-- Resource 1: ICP Discovery Framework
(
  'global', 
  1, 
  'buyer_intelligence',
  'ICP Discovery Framework',
  'Comprehensive framework for identifying and validating your ideal customer profile',
  '{
    "summary": "Define and validate your ideal customer profile using proven methodologies",
    "sections": [
      {
        "title": "Firmographic Criteria",
        "content": "Industry, company size, revenue range, growth stage, geographic location",
        "action": "Define your target company characteristics"
      },
      {
        "title": "Technographic Criteria", 
        "content": "Technology stack, digital maturity, integration requirements",
        "action": "Identify technology indicators of good-fit customers"
      },
      {
        "title": "Behavioral Criteria",
        "content": "Buying patterns, decision-making process, pain point triggers",
        "action": "Document behavioral signals that indicate purchase readiness"
      }
    ],
    "deliverables": ["ICP Definition Template", "Scoring Matrix", "Target Account List"],
    "estimatedTime": "2-3 hours"
  }'::jsonb,
  'completed',
  ARRAY['pdf', 'docx', 'csv'],
  0,
  NOW(),
  NOW()
),

-- Resource 2: Target Buyer Personas
(
  'global', 
  1, 
  'buyer_intelligence',
  'Target Buyer Personas',
  'Detailed buyer persona templates with decision-making insights',
  '{
    "summary": "Create actionable buyer personas for your target accounts",
    "sections": [
      {
        "title": "Persona Demographics",
        "content": "Role, seniority, department, responsibilities, success metrics",
        "action": "Build 3-5 distinct buyer personas"
      },
      {
        "title": "Pain Points & Goals",
        "content": "Current challenges, desired outcomes, success criteria",
        "action": "Map pain points to your solution capabilities"
      },
      {
        "title": "Buying Process",
        "content": "Research habits, evaluation criteria, decision authority, timeline",
        "action": "Document how each persona evaluates solutions"
      }
    ],
    "deliverables": ["Persona Cards", "Messaging Guide", "Objection Handlers"],
    "estimatedTime": "3-4 hours"
  }'::jsonb,
  'completed',
  ARRAY['pdf', 'docx'],
  0,
  NOW(),
  NOW()
),

-- Resource 3: Empathy Map
(
  'global', 
  1, 
  'buyer_intelligence',
  'Empathy Mapping Framework',
  'Deep empathy mapping for understanding buyer perspectives',
  '{
    "summary": "Map the emotional and practical journey of your buyers",
    "sections": [
      {
        "title": "Think & Feel",
        "content": "Worries, aspirations, frustrations, what keeps them up at night",
        "action": "Document internal thoughts and emotions"
      },
      {
        "title": "See & Hear",
        "content": "What they observe in their market, what peers say, influencer impact",
        "action": "Map external influences on decision-making"
      },
      {
        "title": "Say & Do",
        "content": "Public statements, actual behaviors, contradictions, attitudes",
        "action": "Identify gaps between stated needs and actions"
      },
      {
        "title": "Pain & Gain",
        "content": "Obstacles, fears, wants, needs, measures of success",
        "action": "Define problems you solve and value you create"
      }
    ],
    "deliverables": ["Empathy Map Canvas", "Journey Map", "Messaging Playbook"],
    "estimatedTime": "2-3 hours"
  }'::jsonb,
  'completed',
  ARRAY['pdf', 'docx'],
  0,
  NOW(),
  NOW()
),

-- Resource 4: Product Potential Assessment
(
  'global', 
  1, 
  'strategic_tools',
  'Product Potential Assessment',
  'Strategic framework for evaluating product-market fit and growth potential',
  '{
    "summary": "Assess market opportunity and product-market fit systematically",
    "sections": [
      {
        "title": "Market Sizing",
        "content": "TAM, SAM, SOM analysis, market growth rate, competitive density",
        "action": "Calculate addressable market opportunity"
      },
      {
        "title": "Product-Market Fit Score",
        "content": "Problem validation, solution fit, willingness to pay, switching costs",
        "action": "Rate your product-market fit (1-10 scale)"
      },
      {
        "title": "Competitive Positioning",
        "content": "Direct competitors, alternatives, differentiation, moats",
        "action": "Map competitive landscape and unique advantages"
      },
      {
        "title": "Growth Potential",
        "content": "Expansion opportunities, scalability, network effects, virality",
        "action": "Identify paths to rapid growth"
      }
    ],
    "deliverables": ["Market Assessment Report", "Competitive Matrix", "Growth Roadmap"],
    "estimatedTime": "4-5 hours"
  }'::jsonb,
  'completed',
  ARRAY['pdf', 'docx', 'csv'],
  0,
  NOW(),
  NOW()
)
ON CONFLICT (customer_id, title) DO UPDATE SET
  description = EXCLUDED.description,
  content = EXCLUDED.content,
  generation_status = EXCLUDED.generation_status,
  export_formats = EXCLUDED.export_formats,
  updated_at = NOW();

-- ============================================
-- PART 2: CUSTOMER DATA WITH MVP CONTENT
-- ============================================
-- Purpose: Store ICP input data, assessment results, cost calculator data

-- Brandon Geter (Admin - Full Testing Access)
INSERT INTO customer_assets (
  customer_id,
  customer_name,
  email,
  company,
  payment_status,
  content_status,
  competency_level,
  icp_content,
  detailed_icp_analysis,
  target_buyer_personas,
  competency_progress,
  cost_calculator_content,
  business_case_content,
  created_at,
  updated_at
) VALUES (
  (SELECT id FROM auth.users WHERE email = 'geter@humusnshore.org'),
  'Brandon Geter',
  'geter@humusnshore.org',
  'Humus & Shore',
  'Completed',
  'Ready',
  'Revenue Intelligence Expert',
  
  -- ICP Content (product details for widget testing)
  '{
    "productName": "H&S Revenue Intelligence Platform",
    "productDescription": "AI-powered platform for B2B sales teams to accelerate deal velocity",
    "targetMarket": "B2B SaaS companies",
    "pricePoint": "$15,000-50,000 ACV",
    "keyFeatures": ["ICP Analysis", "Buyer Intelligence", "Deal Acceleration"],
    "valueProposition": "Reduce sales cycle by 40% through buyer-centric intelligence"
  }'::jsonb,

  -- Detailed ICP Analysis (generated from widgets)
  '{
    "firmographic": {
      "industries": ["B2B SaaS", "Professional Services", "Financial Services"],
      "companySize": "50-500 employees",
      "revenue": "$10M-$100M ARR",
      "growthStage": "Series A to Series C"
    },
    "technographic": {
      "currentStack": ["Salesforce", "HubSpot", "Outreach"],
      "integrationNeeds": "CRM, Sales Engagement, Data Enrichment"
    },
    "behavioral": {
      "painPoints": ["Long sales cycles", "Low win rates", "Poor qualification"],
      "triggers": ["New sales leader", "Revenue targets missed", "Market expansion"]
    }
  }'::jsonb,

  -- Buyer Personas (from widget)
  '{
    "personas": [
      {
        "name": "VP Sales",
        "role": "Primary Economic Buyer",
        "painPoints": ["Revenue predictability", "Team productivity", "Win rate optimization"],
        "goals": ["Hit quarterly targets", "Scale team efficiency", "Reduce churn"],
        "decisionCriteria": ["ROI proof", "Ease of adoption", "Integration capability"]
      },
      {
        "name": "Sales Enablement Manager",
        "role": "Technical Evaluator", 
        "painPoints": ["Rep onboarding time", "Content relevance", "Tool adoption"],
        "goals": ["Faster ramp time", "Higher activity quality", "Data-driven coaching"],
        "decisionCriteria": ["Ease of use", "Training resources", "Analytics depth"]
      }
    ]
  }'::jsonb,

  -- Mock Assessment Results
  '{
    "overallScore": 78,
    "buyerScore": 82,
    "techScore": 74,
    "competencyLevel": "Advanced Practitioner",
    "strengths": ["Buyer Research", "Value Articulation"],
    "gaps": ["Technical Translation", "Competitive Positioning"],
    "tier1Progress": 100,
    "tier2Progress": 65,
    "tier3Progress": 30
  }'::jsonb,

  -- Cost Calculator Data
  '{
    "currentState": {
      "avgDealSize": 45000,
      "salesCycleLength": 120,
      "winRate": 22,
      "monthlyDeals": 8
    },
    "calculatedCosts": {
      "lostRevenue": 540000,
      "wastedEffort": 180000,
      "opportunityCost": 320000,
      "totalAnnualCost": 1040000
    },
    "potentialGains": {
      "withImprovement": {
        "cycleReduction": 40,
        "winRateIncrease": 15,
        "additionalRevenue": 890000
      }
    }
  }'::jsonb,

  -- One-Page Business Case
  '{
    "executiveSummary": "Investment in buyer intelligence reduces sales cycle by 40% and increases win rate by 15%, generating $890K additional annual revenue.",
    "problemStatement": "Current sales process results in $1.04M annual cost of inaction through long cycles, low win rates, and missed opportunities.",
    "proposedSolution": "H&S Revenue Intelligence Platform provides AI-powered buyer insights to accelerate deals and improve win rates.",
    "financialImpact": {
      "investment": 50000,
      "yearOneReturn": 890000,
      "roi": "1780%",
      "paybackPeriod": "6 weeks"
    },
    "keyMetrics": {
      "cycleTimeReduction": "48 days (40%)",
      "winRateImprovement": "+15 percentage points",
      "revenueImpact": "$890K year one"
    },
    "implementation": {
      "timeline": "90 days",
      "resources": "1 project lead, 2 sales ops analysts",
      "risks": "Low - proven methodology, existing tool integrations"
    }
  }'::jsonb,
  NOW(),
  NOW()
)
ON CONFLICT (email) DO UPDATE SET
  customer_id = EXCLUDED.customer_id,
  customer_name = EXCLUDED.customer_name,
  company = EXCLUDED.company,
  payment_status = EXCLUDED.payment_status,
  content_status = EXCLUDED.content_status,
  competency_level = EXCLUDED.competency_level,
  icp_content = EXCLUDED.icp_content,
  detailed_icp_analysis = EXCLUDED.detailed_icp_analysis,
  target_buyer_personas = EXCLUDED.target_buyer_personas,
  competency_progress = EXCLUDED.competency_progress,
  cost_calculator_content = EXCLUDED.cost_calculator_content,
  business_case_content = EXCLUDED.business_case_content,
  updated_at = NOW();

-- Dotun Odewale (Test User - Limited Access)
INSERT INTO customer_assets (
  customer_id,
  customer_name,
  email,
  company,
  payment_status,
  content_status,
  competency_level,
  icp_content,
  detailed_icp_analysis,
  target_buyer_personas,
  competency_progress,
  cost_calculator_content,
  business_case_content,
  created_at,
  updated_at
) VALUES (
  (SELECT id FROM auth.users WHERE email = 'dotun@adesolarenergy.com'),
  'Dotun Odewale',
  'dotun@adesolarenergy.com',
  'Adesola Renewable Energy',
  'Completed',
  'Ready',
  'Foundation',
  
  -- Product details for ICP widgets
  '{
    "productName": "Commercial Solar Solutions",
    "productDescription": "Turnkey solar installations for small to medium businesses",
    "targetMarket": "SMB facilities management",
    "pricePoint": "$50,000-$200,000 project value",
    "keyFeatures": ["Energy audit", "Custom design", "Installation", "Monitoring"],
    "valueProposition": "Reduce energy costs by 40% with zero upfront investment"
  }'::jsonb,

  -- ICP Analysis
  '{
    "firmographic": {
      "industries": ["Manufacturing", "Warehousing", "Retail"],
      "companySize": "25-200 employees",
      "revenue": "$5M-$50M annual revenue",
      "location": "California, Texas, Arizona"
    },
    "facilities": {
      "roofSize": "10,000+ sq ft",
      "energyUsage": "$5,000+ monthly electric bill",
      "ownership": "Owned facilities preferred"
    },
    "behavioral": {
      "painPoints": ["Rising energy costs", "Sustainability mandates", "Budget constraints"],
      "triggers": ["Lease renewal", "Facility expansion", "ESG reporting requirements"]
    }
  }'::jsonb,

  -- Buyer Personas
  '{
    "personas": [
      {
        "name": "Facilities Director",
        "role": "Primary Decision Maker",
        "painPoints": ["Energy cost volatility", "Equipment maintenance", "Sustainability pressure"],
        "goals": ["Reduce operating costs", "Improve facility efficiency", "Meet ESG goals"],
        "decisionCriteria": ["ROI clarity", "No upfront cost", "Proven track record"]
      }
    ]
  }'::jsonb,

  -- Mock Assessment Results (lower scores - foundation level)
  '{
    "overallScore": 45,
    "buyerScore": 52,
    "techScore": 38,
    "competencyLevel": "Foundation",
    "strengths": ["Customer Focus"],
    "gaps": ["ICP Definition", "Value Quantification", "Buyer Journey Mapping"],
    "tier1Progress": 35,
    "tier2Progress": 0,
    "tier3Progress": 0
  }'::jsonb,

  -- Cost Calculator Data
  '{
    "currentState": {
      "avgDealSize": 125000,
      "salesCycleLength": 180,
      "winRate": 18,
      "monthlyDeals": 3
    },
    "calculatedCosts": {
      "lostRevenue": 450000,
      "wastedEffort": 120000,
      "opportunityCost": 280000,
      "totalAnnualCost": 850000
    },
    "potentialGains": {
      "withImprovement": {
        "cycleReduction": 35,
        "winRateIncrease": 12,
        "additionalRevenue": 520000
      }
    }
  }'::jsonb,

  -- One-Page Business Case
  '{
    "executiveSummary": "Implementing buyer intelligence reduces sales cycle by 35% and increases win rate by 12%, generating $520K additional annual revenue.",
    "problemStatement": "Current sales approach results in $850K annual cost through extended sales cycles, low conversion rates, and limited market penetration.",
    "proposedSolution": "Systematic buyer intelligence and ICP-driven targeting to accelerate commercial solar sales.",
    "financialImpact": {
      "investment": 25000,
      "yearOneReturn": 520000,
      "roi": "2080%",
      "paybackPeriod": "5 weeks"
    },
    "keyMetrics": {
      "cycleTimeReduction": "63 days (35%)",
      "winRateImprovement": "+12 percentage points",
      "revenueImpact": "$520K year one"
    },
    "implementation": {
      "timeline": "60 days",
      "resources": "Sales manager + 1 analyst",
      "risks": "Low - proven frameworks, minimal tech requirements"
    }
  }'::jsonb,
  NOW(),
  NOW()
)
ON CONFLICT (email) DO UPDATE SET
  customer_id = EXCLUDED.customer_id,
  customer_name = EXCLUDED.customer_name,
  company = EXCLUDED.company,
  payment_status = EXCLUDED.payment_status,
  content_status = EXCLUDED.content_status,
  competency_level = EXCLUDED.competency_level,
  icp_content = EXCLUDED.icp_content,
  detailed_icp_analysis = EXCLUDED.detailed_icp_analysis,
  target_buyer_personas = EXCLUDED.target_buyer_personas,
  competency_progress = EXCLUDED.competency_progress,
  cost_calculator_content = EXCLUDED.cost_calculator_content,
  business_case_content = EXCLUDED.business_case_content,
  updated_at = NOW();

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Verify resources were created
DO $$
DECLARE
  resource_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO resource_count FROM resources WHERE customer_id = 'global';
  
  IF resource_count = 4 THEN
    RAISE NOTICE '✅ SUCCESS: 4 resources created successfully';
  ELSE
    RAISE EXCEPTION '❌ ERROR: Expected 4 resources, found %', resource_count;
  END IF;
END $$;

-- Verify customer assets were created/updated
DO $$
DECLARE
  brandon_count INTEGER;
  dotun_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO brandon_count FROM customer_assets WHERE email = 'geter@humusnshore.org';
  SELECT COUNT(*) INTO dotun_count FROM customer_assets WHERE email = 'dotun@adesolarenergy.com';
  
  IF brandon_count = 1 AND dotun_count = 1 THEN
    RAISE NOTICE '✅ SUCCESS: Brandon and Dotun customer records created/updated successfully';
  ELSE
    RAISE EXCEPTION '❌ ERROR: Expected 1 record each for Brandon and Dotun - Brandon: %, Dotun: %', brandon_count, dotun_count;
  END IF;
END $$;

-- Verify specific data integrity
DO $$
DECLARE
  brandon_exists BOOLEAN;
  dotun_exists BOOLEAN;
BEGIN
  SELECT EXISTS(SELECT 1 FROM customer_assets WHERE email = 'geter@humusnshore.org') INTO brandon_exists;
  SELECT EXISTS(SELECT 1 FROM customer_assets WHERE email = 'dotun@adesolarenergy.com') INTO dotun_exists;
  
  IF brandon_exists AND dotun_exists THEN
    RAISE NOTICE '✅ SUCCESS: Both Brandon and Dotun records created successfully';
  ELSE
    RAISE EXCEPTION '❌ ERROR: Missing customer records - Brandon: %, Dotun: %', brandon_exists, dotun_exists;
  END IF;
END $$;

-- ============================================
-- MIGRATION COMPLETION
-- ============================================

-- Record successful completion (idempotent)
INSERT INTO public.migration_log (migration_name, executed_at, status, details)
VALUES ('01_mvp_seed', now(), 'success', 'MVP database seeding completed successfully - 4 resources and 2 customer records created')
ON CONFLICT (migration_name) DO UPDATE SET
  executed_at = NOW(),
  status = 'success',
  details = 'MVP database seeding completed successfully - 4 resources and 2 customer records created';

-- Final success message
DO $$
BEGIN
  RAISE NOTICE '🎉 MVP DATABASE SEEDING COMPLETED SUCCESSFULLY!';
  RAISE NOTICE '📊 Created: 4 resources (Tier 1 Core) + 2 customer records (Brandon & Dotun)';
  RAISE NOTICE '🎯 Ready for testing: ICP Tool, Resources Library, Assessment, Cost Calculator';
  RAISE NOTICE '✅ All verification checks passed';
END $$;
