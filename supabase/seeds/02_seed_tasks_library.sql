-- Seed Data: Tasks Library
-- Created: 2025-10-11
-- Purpose: Populate tasks_library with 32 tasks for foundation-seed and growth-series-a milestones
-- Status: Recreated from live Supabase data on 2025-10-13

-- ============================================================================
-- FOUNDATION-SEED TASKS (12 tasks)
-- ============================================================================
-- Focus: Customer Discovery, ICP Development, Sales Process, Value Communication

INSERT INTO tasks_library (
    task_code, name, description, category, stage_milestone, priority,
    competency_area, estimated_time, business_impact, prerequisites,
    platform_connection, resources, source_table, is_active
) VALUES
-- Customer Analysis Tasks (6)
('gather-customer-feedback', 'Gather and analyze customer feedback to refine the product', 'Collect and systematically analyze customer feedback to identify product improvement opportunities and validate product-market fit', 'Customer Discovery', 'foundation-seed', 'critical', 'customerAnalysis', '2-4 hours', 'Direct product improvements based on real user needs', 'Initial product launched', '{"tool": "icp", "feature": "feedback-analysis", "description": "Use ICP Analysis to understand buyer feedback patterns systematically"}'::jsonb, '[]'::jsonb, 'seed', true),

('define-icp', 'Define Ideal Customer Profile (ICP)', 'Create a detailed profile of your ideal customer including company characteristics, pain points, and buying behavior', 'ICP Development', 'foundation-seed', 'critical', 'customerAnalysis', '3-5 hours', 'Focus sales and marketing efforts on highest-value prospects', null, '{"tool": "icp", "feature": "icp-builder", "description": "Direct platform tool usage - core ICP development capability"}'::jsonb, '[]'::jsonb, 'seed', true),

('conduct-customer-interviews', 'Conduct customer interviews to validate product-market fit', 'Run structured interviews with target customers to validate assumptions and gather insights', 'Customer Discovery', 'foundation-seed', 'high', 'customerAnalysis', '4-6 hours', 'Validate product direction with real customer insights', 'ICP defined', '{"tool": "icp", "feature": "interview-templates", "description": "Use structured interview frameworks"}'::jsonb, '[]'::jsonb, 'seed', true),

('analyze-user-behavior', 'Analyze user behavior and usage patterns', 'Track and analyze how users interact with your product to identify engagement patterns', 'Product Analytics', 'foundation-seed', 'medium', 'customerAnalysis', '2-3 hours', 'Identify feature adoption and usage bottlenecks', 'Product analytics setup', null, '[]'::jsonb, 'seed', true),

('create-buyer-personas', 'Create detailed buyer personas', 'Develop comprehensive personas representing your key customer segments', 'ICP Development', 'foundation-seed', 'high', 'customerAnalysis', '3-4 hours', 'Align team on target customer understanding', 'Customer research completed', '{"tool": "icp", "feature": "persona-builder", "description": "Build comprehensive buyer persona documentation"}'::jsonb, '[]'::jsonb, 'seed', true),

('map-customer-journey', 'Map customer journey and touchpoints', 'Document the complete customer journey from awareness to purchase and beyond', 'Customer Experience', 'foundation-seed', 'medium', 'customerAnalysis', '2-3 hours', 'Identify opportunities to improve customer experience', 'Customer personas defined', null, '[]'::jsonb, 'seed', true),

-- Value Communication Tasks (6)
('build-sales-process', 'Build a repeatable sales process', 'Create a systematic, repeatable sales process that can scale', 'Sales Operations', 'foundation-seed', 'critical', 'valueCommunication', '4-6 hours', 'Enable consistent sales execution and team scaling', 'ICP defined', '{"tool": "financial", "feature": "cost-calculator", "description": "Use Cost Calculator to quantify value in systematic sales process"}'::jsonb, '[]'::jsonb, 'seed', true),

('develop-sales-pitch', 'Develop a compelling sales pitch and messaging', 'Create persuasive messaging that resonates with target buyers', 'Sales Enablement', 'foundation-seed', 'high', 'valueCommunication', '3-5 hours', 'Improve conversion rates with effective messaging', 'Value proposition defined', null, '[]'::jsonb, 'seed', true),

('create-value-proposition', 'Create value proposition documentation', 'Document clear, compelling value propositions for each buyer persona', 'Messaging', 'foundation-seed', 'high', 'valueCommunication', '2-4 hours', 'Align team on value messaging', 'Buyer personas complete', null, '[]'::jsonb, 'seed', true),

('build-roi-calculators', 'Build ROI calculators for prospects', 'Create tools to demonstrate quantifiable ROI for prospects', 'Sales Tools', 'foundation-seed', 'medium', 'valueCommunication', '4-6 hours', 'Accelerate deals with financial justification', 'Value metrics identified', '{"tool": "financial", "feature": "roi-calculator", "description": "Build ROI models showing prospect value"}'::jsonb, '[]'::jsonb, 'seed', true),

('create-sales-materials', 'Create sales enablement materials', 'Develop pitch decks, one-pagers, and other sales collateral', 'Sales Enablement', 'foundation-seed', 'medium', 'valueCommunication', '3-4 hours', 'Arm sales team with effective materials', 'Messaging finalized', null, '[]'::jsonb, 'seed', true),

('design-demo-materials', 'Design demo and presentation materials', 'Create compelling demo scripts and presentation materials', 'Sales Enablement', 'foundation-seed', 'medium', 'valueCommunication', '3-5 hours', 'Improve demo effectiveness and conversion', 'Product features stabilized', null, '[]'::jsonb, 'seed', true)

ON CONFLICT (task_code) DO NOTHING;

-- ============================================================================
-- GROWTH-SERIES-A TASKS (20 tasks)
-- ============================================================================
-- Focus: Customer Segmentation, Sales Scaling, Team Building, Executive Readiness

INSERT INTO tasks_library (
    task_code, name, description, category, stage_milestone, priority,
    competency_area, estimated_time, business_impact, prerequisites,
    platform_connection, resources, source_table, is_active
) VALUES
-- Customer Analysis Tasks (4)
('refine-target-customers', 'Refine understanding of target customers to focus sales efforts', 'Deepen customer understanding to optimize sales targeting and prioritization', 'Customer Segmentation', 'growth-series-a', 'high', 'customerAnalysis', '3-4 hours', 'Improve sales efficiency by focusing on best-fit prospects', 'Initial customer base established', '{"tool": "icp", "feature": "rating-system", "description": "Use ICP rating system to prioritize prospect outreach"}'::jsonb, '[]'::jsonb, 'series-a', true),

('build-customer-success-team', 'Build a Customer Success Team', 'Establish dedicated customer success function to drive retention and expansion', 'Team Building', 'growth-series-a', 'high', 'customerAnalysis', '1-2 weeks', 'Reduce churn and increase customer lifetime value', 'Product-market fit achieved', null, '[]'::jsonb, 'series-a', true),

('segment-customers-by-value', 'Segment customers by value and usage', 'Create systematic customer segmentation based on value and engagement', 'Customer Analytics', 'growth-series-a', 'medium', 'customerAnalysis', '2-3 hours', 'Enable targeted customer strategies', 'Customer data available', '{"tool": "icp", "feature": "segmentation", "description": "Apply systematic customer segmentation framework"}'::jsonb, '[]'::jsonb, 'series-a', true),

('implement-feedback-loops', 'Implement customer feedback loops', 'Create systematic processes for gathering and acting on customer feedback', 'Customer Experience', 'growth-series-a', 'medium', 'customerAnalysis', '3-4 hours', 'Continuous product improvement from customer insights', 'Customer success team in place', null, '[]'::jsonb, 'series-a', true),

-- Value Communication Tasks (6)
('start-sales-pipeline', 'Start building a sales pipeline and closing deals', 'Systematically build and manage a healthy sales pipeline', 'Sales Operations', 'growth-series-a', 'critical', 'valueCommunication', '4-6 hours', 'Generate predictable revenue through systematic pipeline management', 'Sales process defined', '{"tool": "financial", "feature": "business-case-builder", "description": "Use Business Case Builder to close deals with financial justification"}'::jsonb, '[]'::jsonb, 'series-a', true),

('implement-sales-automation', 'Implement sales automation and CRM tools to improve efficiency', 'Deploy CRM and sales automation to scale sales operations', 'Sales Technology', 'growth-series-a', 'high', 'valueCommunication', '1-2 weeks', 'Scale sales efficiency and tracking', 'Sales process working', null, '[]'::jsonb, 'series-a', true),

('optimize-pricing-packaging', 'Optimize Pricing & Packaging', 'Refine pricing strategy and packaging to maximize value capture', 'Pricing Strategy', 'growth-series-a', 'high', 'valueCommunication', '1-2 weeks', 'Increase average deal size and win rates', 'Initial pricing validated', '{"tool": "financial", "feature": "pricing-optimizer", "description": "Model pricing scenarios and impact"}'::jsonb, '[]'::jsonb, 'series-a', true),

('develop-competitive-positioning', 'Develop competitive positioning materials', 'Create battle cards and competitive positioning documentation', 'Sales Enablement', 'growth-series-a', 'medium', 'valueCommunication', '2-3 hours', 'Win competitive deals with strong differentiation', 'Competitive analysis complete', null, '[]'::jsonb, 'series-a', true),

('implement-lead-qualification', 'Implement lead qualification framework', 'Create systematic lead scoring and qualification process', 'Sales Operations', 'growth-series-a', 'medium', 'valueCommunication', '2-3 hours', 'Focus sales efforts on highest-quality opportunities', 'ICP clearly defined', null, '[]'::jsonb, 'series-a', true),

-- Executive Readiness Tasks (10)
('hire-sales-leader', 'Hire a dedicated sales leader to build and manage the team', 'Recruit experienced sales leader to scale the sales organization', 'Team Building', 'growth-series-a', 'critical', 'executiveReadiness', '1-3 months', 'Enable sales team scaling and professional management', 'Sales process validated', null, '[]'::jsonb, 'series-a', true),

('implement-sales-training', 'Implement a sales training program and provide ongoing coaching', 'Create formal sales training and coaching programs', 'Team Development', 'growth-series-a', 'high', 'executiveReadiness', '1-2 weeks', 'Improve team performance and consistency', 'Sales leader in place', null, '[]'::jsonb, 'series-a', true),

('prepare-series-a', 'Prepare for Series A funding by demonstrating strong growth', 'Build metrics, materials, and story for Series A fundraising', 'Fundraising', 'growth-series-a', 'critical', 'executiveReadiness', '2-4 weeks', 'Secure growth capital to scale the business', 'Strong growth metrics', '{"tool": "financial", "feature": "investor-materials", "description": "Generate investor-ready financial projections"}'::jsonb, '[]'::jsonb, 'series-a', true),

('expand-sales-team', 'Expand Sales Team & Channels', 'Scale the sales team and explore new sales channels', 'Team Building', 'growth-series-a', 'high', 'executiveReadiness', '1-3 months', 'Accelerate revenue growth through team expansion', 'Sales process proven', null, '[]'::jsonb, 'series-a', true),

('develop-partnerships', 'Develop Strategic Partnerships', 'Build strategic partnerships to expand market reach', 'Business Development', 'growth-series-a', 'medium', 'executiveReadiness', '1-3 months', 'Access new markets and customer segments', 'Product-market fit clear', null, '[]'::jsonb, 'series-a', true),

('build-board-reporting', 'Build board reporting and metrics dashboard', 'Create executive dashboard and board reporting systems', 'Executive Operations', 'growth-series-a', 'high', 'executiveReadiness', '1-2 weeks', 'Enable data-driven decision making', 'Key metrics defined', null, '[]'::jsonb, 'series-a', true),

('create-investor-updates', 'Create investor updates and communication', 'Establish regular investor communication cadence and materials', 'Investor Relations', 'growth-series-a', 'medium', 'executiveReadiness', '4-6 hours', 'Maintain strong investor relationships', 'Board established', null, '[]'::jsonb, 'series-a', true),

('establish-executive-structure', 'Establish executive team structure', 'Build out C-suite and senior leadership team', 'Team Building', 'growth-series-a', 'high', 'executiveReadiness', '2-6 months', 'Create scalable leadership structure', 'Series A raised', null, '[]'::jsonb, 'series-a', true),

('develop-strategic-planning', 'Develop strategic planning processes', 'Implement formal strategic planning and review processes', 'Executive Operations', 'growth-series-a', 'medium', 'executiveReadiness', '1-2 weeks', 'Align organization on strategic priorities', 'Executive team in place', null, '[]'::jsonb, 'series-a', true),

('implement-okrs', 'Implement OKRs and performance management', 'Deploy OKR framework and performance management systems', 'Executive Operations', 'growth-series-a', 'medium', 'executiveReadiness', '1-2 weeks', 'Align organization and track progress', 'Leadership team established', null, '[]'::jsonb, 'series-a', true),

('create-expansion-strategy', 'Create market expansion strategy', 'Develop strategy for geographic or vertical market expansion', 'Strategic Planning', 'growth-series-a', 'medium', 'executiveReadiness', '2-4 weeks', 'Plan for sustainable growth and market leadership', 'Core market established', null, '[]'::jsonb, 'series-a', true)

ON CONFLICT (task_code) DO NOTHING;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Verify seed data was inserted correctly
DO $$
DECLARE
    total_count INTEGER;
    seed_count INTEGER;
    series_a_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_count FROM tasks_library;
    SELECT COUNT(*) INTO seed_count FROM tasks_library WHERE stage_milestone = 'foundation-seed';
    SELECT COUNT(*) INTO series_a_count FROM tasks_library WHERE stage_milestone = 'growth-series-a';

    RAISE NOTICE 'Tasks Library Seed Complete:';
    RAISE NOTICE '  Total tasks: %', total_count;
    RAISE NOTICE '  Foundation-Seed: %', seed_count;
    RAISE NOTICE '  Growth-Series-A: %', series_a_count;

    IF total_count < 32 THEN
        RAISE WARNING 'Expected 32 tasks, but found %', total_count;
    END IF;
END $$;
