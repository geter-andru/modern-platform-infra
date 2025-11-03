-- ===============================================
-- PERFORMANCE INDEXES FOR EXISTING TABLES
-- Date: 2025-10-27
-- Purpose: Optimize query performance for ICP tool
-- Reference: SUPABASE_SCHEMA_SYNTAX_REFERENCE.md
-- ===============================================

-- ===============================================
-- ICP_FRAMEWORKS TABLE INDEXES
-- ===============================================

-- User lookup (most common query)
CREATE INDEX IF NOT EXISTS idx_icp_frameworks_user_id
  ON icp_frameworks(user_id);

-- Recent frameworks first
CREATE INDEX IF NOT EXISTS idx_icp_frameworks_created_at
  ON icp_frameworks(created_at DESC);

-- Product name search (use TEXT not VARCHAR)
CREATE INDEX IF NOT EXISTS idx_icp_frameworks_product_name
  ON icp_frameworks(product_name);

-- JSONB search on framework structure
CREATE INDEX IF NOT EXISTS idx_icp_frameworks_framework_gin
  ON icp_frameworks USING GIN (framework);

-- Full-text search on product descriptions
CREATE INDEX IF NOT EXISTS idx_icp_frameworks_description_fts
  ON icp_frameworks
  USING GIN (to_tsvector('english', product_description));

-- Comments for documentation
COMMENT ON INDEX idx_icp_frameworks_user_id IS 'Fast customer framework lookups';
COMMENT ON INDEX idx_icp_frameworks_framework_gin IS 'Enable JSONB array/object searches within framework';


-- ===============================================
-- COMPANY_RESEARCH TABLE INDEXES
-- ===============================================

-- User lookup
CREATE INDEX IF NOT EXISTS idx_company_research_user_id
  ON company_research(user_id);

-- URL lookup (for cache hits)
CREATE INDEX IF NOT EXISTS idx_company_research_url
  ON company_research(company_url);

-- Recent research first
CREATE INDEX IF NOT EXISTS idx_company_research_cached_at
  ON company_research(cached_at DESC);

-- JSONB search on research data
CREATE INDEX IF NOT EXISTS idx_company_research_data_gin
  ON company_research USING GIN (research_data);

-- Company name search
CREATE INDEX IF NOT EXISTS idx_company_research_name_fts
  ON company_research
  USING GIN (to_tsvector('english', company_name));

-- Comments for documentation
COMMENT ON INDEX idx_company_research_url IS 'Fast URL-based cache lookups';
COMMENT ON INDEX idx_company_research_data_gin IS 'Enable JSONB searches on research_data';
