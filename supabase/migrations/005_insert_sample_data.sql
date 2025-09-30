-- Insert sample data for testing and admin access
-- Includes CUST_02 test user and enhanced admin user data

-- Insert test user CUST_02 (similar to current Airtable test user)
INSERT INTO customer_assets (
  customer_id,
  customer_name,
  email,
  company,
  access_token,
  payment_status,
  content_status,
  usage_count,
  competency_level,
  development_plan_active,
  icp_content,
  cost_calculator_content,
  business_case_content,
  competency_progress,
  tool_access_status,
  professional_milestones,
  daily_objectives,
  user_preferences,
  workflow_progress,
  usage_analytics
) VALUES (
  'CUST_02',
  'Test User Sarah',
  'sarah.test@example.com',
  'Test Company Inc',
  'test-token-123456',
  'Completed',
  'Ready',
  15,
  'Systematic Buyer Understanding',
  true,
  '{"framework": "comprehensive", "segments": [{"name": "Enterprise SaaS", "score": 85}, {"name": "Mid-Market Tech", "score": 72}], "confidence": 78}',
  '{"scenarios": ["conservative", "realistic", "aggressive"], "calculations": {"roi": 245, "payback": 12, "totalCost": 125000, "savings": 180000}}',
  '{"templates": ["pilot_program"], "value": 180000, "timeline": "6-12 months", "stakeholders": ["CTO", "CFO", "Head of Operations"]}',
  '{"current_level": "Systematic Buyer Understanding", "points_earned": 1850, "areas_of_focus": ["Value Communication", "ROI Analysis"], "last_updated": "2024-08-27"}',
  '{"icp_analysis": true, "cost_calculator": true, "business_case_builder": true, "advanced_features": false}',
  '{"achievements": [{"title": "First ICP Analysis", "description": "Completed comprehensive ICP framework", "date": "2024-08-20", "impact": "Improved prospect qualification"}], "current_goals": ["Master ROI presentations", "Develop stakeholder communication"], "next_milestone": {"target": "Q4 2024", "goal": "Advanced Sales Execution level"}}',
  '{"today": [{"priority": "high", "task": "Review enterprise prospects", "timeBlock": "9:00-10:30", "outcome": "Qualify 2 opportunities"}], "thisWeek": ["Complete cost calculator training", "Practice stakeholder presentations"], "metrics": {"completionRate": 75, "focusTime": "4.2 hours", "keyResults": 2}}',
  '{"interface_theme": "dark", "notification_settings": {"email": true, "milestone_alerts": true}, "workflow_preferences": {"auto_save": true, "detailed_analysis": true}}',
  '{"tools_completed": ["icp_analysis", "cost_calculator"], "current_step": "business_case_builder", "completion_percentage": 67}',
  '{"session_count": 18, "total_time_spent": 320, "feature_usage": {"icp": 8, "calculator": 6, "business_case": 4}}'
);

-- Insert enhanced sample data for test user CUST_02 with revolutionary features
UPDATE customer_assets SET
  technical_translation_data = '{
    "templates": [
      {"stakeholder": "CTO", "focus": "architecture", "templates": ["scalability_framework", "security_compliance"]},
      {"stakeholder": "CFO", "focus": "financial", "templates": ["roi_calculator", "cost_benefit_analysis"]},
      {"stakeholder": "COO", "focus": "operational", "templates": ["efficiency_metrics", "process_optimization"]}
    ],
    "translation_history": [
      {"from": "technical_spec", "to": "business_value", "date": "2024-08-25", "success": true}
    ]
  }',
  stakeholder_arsenal_data = '{
    "stakeholder_profiles": [
      {"role": "CTO", "priorities": ["scalability", "security", "integration"], "communication_style": "technical_depth"},
      {"role": "CFO", "priorities": ["cost_reduction", "roi", "risk_mitigation"], "communication_style": "metrics_focused"},
      {"role": "COO", "priorities": ["efficiency", "process_improvement", "team_productivity"], "communication_style": "outcome_oriented"}
    ],
    "communication_templates": ["executive_summary", "technical_deep_dive", "financial_analysis"]
  }',
  resources_library_data = '{
    "generated_resources": [
      {"type": "competitive_analysis", "date": "2024-08-26", "quality_score": 88},
      {"type": "market_sizing", "date": "2024-08-25", "quality_score": 92},
      {"type": "stakeholder_mapping", "date": "2024-08-24", "quality_score": 85}
    ],
    "custom_templates": ["enterprise_pilot_framework", "technical_evaluation_criteria"]
  }',
  gamification_state = '{
    "current_level": "Systematic Buyer Understanding",
    "points_balance": 1850,
    "achievements_unlocked": ["first_icp", "cost_analysis_expert", "systematic_approach"],
    "milestone_progress": {
      "current_milestone": "Advanced Sales Execution",
      "progress_percentage": 62,
      "points_needed": 1150
    }
  }'
WHERE customer_id = 'CUST_02';

-- Insert assessment history for CUST_02
INSERT INTO assessment_results (
  customer_id,
  assessment_date,
  customer_analysis_score,
  value_communication_score,
  sales_execution_score,
  overall_score,
  total_progress_points,
  competency_level,
  assessment_type,
  buyer_understanding_score,
  tech_to_value_translation_score,
  stakeholder_communication_score,
  roi_presentation_score,
  industry_focus,
  company_stage,
  revenue_range,
  improvement_areas,
  strength_areas,
  recommended_actions
) VALUES 
(
  'CUST_02',
  '2024-08-20 10:00:00+00',
  65.5,
  58.2,
  52.8,
  58.8,
  800,
  'Customer Intelligence Foundation',
  'baseline',
  62.0,
  55.5,
  61.0,
  48.5,
  'Enterprise SaaS',
  'Series A',
  '$1M-5M',
  '["ROI quantification", "Executive communication", "Value proposition clarity"]',
  '["Technical understanding", "Market analysis", "Product positioning"]',
  '["Practice stakeholder presentations", "Develop ROI frameworks", "Study buyer psychology"]'
),
(
  'CUST_02',
  '2024-08-25 14:30:00+00',
  72.0,
  65.8,
  58.5,
  65.4,
  1850,
  'Systematic Buyer Understanding',
  'progress',
  74.5,
  63.2,
  68.0,
  58.0,
  'Enterprise SaaS',
  'Series A', 
  '$1M-5M',
  '["Advanced ROI modeling", "C-suite communication", "Deal closure techniques"]',
  '["Systematic analysis", "Technical translation", "Buyer research"]',
  '["Master financial modeling", "Practice executive presentations", "Develop proposal templates"]'
);

-- Insert sample customer actions for CUST_02
INSERT INTO customer_actions (
  customer_id,
  action_type,
  action_description,
  impact_level,
  points_awarded,
  base_points,
  impact_multiplier,
  category,
  stakeholder_level,
  action_date,
  duration_minutes,
  outcome_achieved,
  outcome_description,
  verified,
  skills_demonstrated,
  deal_size_range
) VALUES 
(
  'CUST_02',
  'customer_meeting',
  'Discovery call with TechCorp - identified 3 key pain points and budget authority',
  'medium',
  150,
  100,
  1.5,
  'customerAnalysis',
  'Manager',
  '2024-08-22 15:00:00+00',
  45,
  true,
  'Qualified as high-potential prospect with $50K budget',
  true,
  '["buyer_research", "pain_point_identification", "budget_qualification"]',
  '$50K-250K'
),
(
  'CUST_02',
  'value_proposition_delivery',
  'Technical demo with focus on business value - 30min presentation to CTO and COO',
  'high',
  300,
  150,
  2.0,
  'valueCommunication',
  'Executive',
  '2024-08-24 11:00:00+00',
  30,
  true,
  'Secured agreement for pilot program discussion',
  true,
  '["technical_translation", "stakeholder_alignment", "value_communication"]',
  '$50K-250K'
),
(
  'CUST_02',
  'proposal_creation',
  'Created comprehensive pilot proposal with ROI projections and implementation timeline',
  'high',
  400,
  250,
  1.6,
  'salesExecution',
  'Executive',
  '2024-08-26 16:30:00+00',
  120,
  true,
  'Proposal delivered and under review by procurement team',
  false,
  '["proposal_development", "roi_modeling", "implementation_planning"]',
  '$50K-250K'
);

-- Update admin user with additional sample actions
INSERT INTO customer_actions (
  customer_id,
  action_type,
  action_description,
  impact_level,
  points_awarded,
  base_points,
  impact_multiplier,
  category,
  stakeholder_level,
  action_date,
  outcome_achieved,
  verified,
  deal_size_range
) VALUES 
(
  'dru78DR9789SDF862',
  'deal_closure',
  'Closed Enterprise AI pilot program - $75K initial contract with expansion potential',
  'critical',
  1500,
  500,
  3.0,
  'salesExecution',
  'Executive',
  '2024-08-26 17:00:00+00',
  true,
  true,
  '$50K-250K'
),
(
  'dru78DR9789SDF862',
  'referral_generation',
  'Generated qualified referral to sister company based on pilot success',
  'high',
  450,
  300,
  1.5,
  'salesExecution',
  'Executive',
  '2024-08-27 10:00:00+00',
  true,
  true,
  '$250K+'
);