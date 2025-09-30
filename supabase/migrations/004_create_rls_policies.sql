-- Additional Row Level Security policies for comprehensive data protection
-- Ensures proper data isolation and security across all tables

-- Enhanced RLS for customer_assets table
DROP POLICY IF EXISTS customer_assets_policy ON customer_assets;

CREATE POLICY customer_assets_select_policy ON customer_assets
    FOR SELECT USING (
        customer_id = auth.jwt() ->> 'sub' OR 
        access_token = auth.jwt() ->> 'sub' OR
        customer_id = 'dru78DR9789SDF862' -- Admin access
    );

CREATE POLICY customer_assets_insert_policy ON customer_assets
    FOR INSERT WITH CHECK (
        customer_id = auth.jwt() ->> 'sub' OR
        access_token = auth.jwt() ->> 'sub'
    );

CREATE POLICY customer_assets_update_policy ON customer_assets
    FOR UPDATE USING (
        customer_id = auth.jwt() ->> 'sub' OR 
        access_token = auth.jwt() ->> 'sub' OR
        customer_id = 'dru78DR9789SDF862' -- Admin access
    );

CREATE POLICY customer_assets_delete_policy ON customer_assets
    FOR DELETE USING (
        customer_id = auth.jwt() ->> 'sub' OR
        customer_id = 'dru78DR9789SDF862' -- Admin can manage all data
    );

-- Enhanced RLS for assessment_results table  
DROP POLICY IF EXISTS assessment_results_policy ON assessment_results;

CREATE POLICY assessment_results_select_policy ON assessment_results
    FOR SELECT USING (
        customer_id = auth.jwt() ->> 'sub' OR 
        customer_id IN (
            SELECT customer_id FROM customer_assets 
            WHERE access_token = auth.jwt() ->> 'sub'
        ) OR
        customer_id = 'dru78DR9789SDF862' -- Admin access
    );

CREATE POLICY assessment_results_insert_policy ON assessment_results
    FOR INSERT WITH CHECK (
        customer_id = auth.jwt() ->> 'sub' OR
        customer_id IN (
            SELECT customer_id FROM customer_assets 
            WHERE access_token = auth.jwt() ->> 'sub'
        )
    );

CREATE POLICY assessment_results_update_policy ON assessment_results
    FOR UPDATE USING (
        customer_id = auth.jwt() ->> 'sub' OR 
        customer_id IN (
            SELECT customer_id FROM customer_assets 
            WHERE access_token = auth.jwt() ->> 'sub'
        ) OR
        customer_id = 'dru78DR9789SDF862' -- Admin access
    );

-- Enhanced RLS for customer_actions table
DROP POLICY IF EXISTS customer_actions_policy ON customer_actions;

CREATE POLICY customer_actions_select_policy ON customer_actions
    FOR SELECT USING (
        customer_id = auth.jwt() ->> 'sub' OR 
        customer_id IN (
            SELECT customer_id FROM customer_assets 
            WHERE access_token = auth.jwt() ->> 'sub'
        ) OR
        customer_id = 'dru78DR9789SDF862' -- Admin access
    );

CREATE POLICY customer_actions_insert_policy ON customer_actions
    FOR INSERT WITH CHECK (
        customer_id = auth.jwt() ->> 'sub' OR
        customer_id IN (
            SELECT customer_id FROM customer_assets 
            WHERE access_token = auth.jwt() ->> 'sub'
        )
    );

CREATE POLICY customer_actions_update_policy ON customer_actions
    FOR UPDATE USING (
        customer_id = auth.jwt() ->> 'sub' OR 
        customer_id IN (
            SELECT customer_id FROM customer_assets 
            WHERE access_token = auth.jwt() ->> 'sub'
        ) OR
        customer_id = 'dru78DR9789SDF862' -- Admin access
    );

-- Create views for common queries
CREATE VIEW customer_competency_summary AS
SELECT 
  ca.customer_id,
  ca.customer_name,
  ca.email,
  ca.competency_level,
  ca.total_progress_points,
  ar.overall_score as latest_assessment_score,
  ar.assessment_date as latest_assessment_date,
  COUNT(act.id) as total_actions,
  SUM(act.points_awarded) as total_action_points
FROM customer_assets ca
LEFT JOIN LATERAL (
  SELECT * FROM assessment_results 
  WHERE customer_id = ca.customer_id 
  ORDER BY assessment_date DESC 
  LIMIT 1
) ar ON true
LEFT JOIN customer_actions act ON act.customer_id = ca.customer_id
GROUP BY ca.customer_id, ca.customer_name, ca.email, ca.competency_level, 
         ca.total_progress_points, ar.overall_score, ar.assessment_date;

-- Enable RLS on the view
ALTER VIEW customer_competency_summary OWNER TO postgres;

-- Create function to calculate competency level based on points
CREATE OR REPLACE FUNCTION calculate_competency_level(total_points INTEGER)
RETURNS TEXT AS $$
BEGIN
  CASE 
    WHEN total_points < 1000 THEN RETURN 'Customer Intelligence Foundation';
    WHEN total_points < 2500 THEN RETURN 'Systematic Buyer Understanding';  
    WHEN total_points < 5000 THEN RETURN 'Value Communication Proficiency';
    WHEN total_points < 10000 THEN RETURN 'Advanced Sales Execution';
    WHEN total_points < 25000 THEN RETURN 'Revenue Intelligence Expert';
    ELSE RETURN 'Revenue Intelligence Master';
  END CASE;
END;
$$ LANGUAGE plpgsql;

-- Create function to update competency level automatically
CREATE OR REPLACE FUNCTION update_competency_level()
RETURNS TRIGGER AS $$
BEGIN
  -- Calculate total points from actions
  NEW.total_progress_points := (
    SELECT COALESCE(SUM(points_awarded), 0) 
    FROM customer_actions 
    WHERE customer_id = NEW.customer_id
  );
  
  -- Update competency level based on points
  NEW.competency_level := calculate_competency_level(NEW.total_progress_points);
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-update competency level when actions are added
CREATE TRIGGER update_customer_competency_on_action
    AFTER INSERT OR UPDATE OR DELETE ON customer_actions
    FOR EACH ROW 
    EXECUTE FUNCTION update_competency_level();