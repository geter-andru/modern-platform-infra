# SUPABASE SCHEMA SYNTAX REFERENCE
## Critical Reference for All Supabase Database Schema Creation

**Date Created:** January 25, 2025  
**Purpose:** Standardized syntax patterns for Supabase database schema creation  
**Status:** Production-Ready Reference  

---

## 🚨 CRITICAL SYNTAX RULES

### **1. TIMESTAMP SYNTAX**
```sql
-- ✅ CORRECT
created_at TIMESTAMPTZ DEFAULT NOW()
updated_at TIMESTAMPTZ DEFAULT NOW()

-- ❌ WRONG
created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
```

### **2. DATA TYPES**
```sql
-- ✅ CORRECT - Use TEXT instead of VARCHAR
name TEXT NOT NULL
description TEXT
email TEXT UNIQUE NOT NULL

-- ❌ WRONG
name VARCHAR(255) NOT NULL
description VARCHAR(500)
```

### **3. INDEX SYNTAX**
```sql
-- ✅ CORRECT - Separate CREATE INDEX statements
CREATE INDEX IF NOT EXISTS idx_table_column ON table_name(column_name);
CREATE INDEX IF NOT EXISTS idx_table_created_at ON table_name(created_at DESC);

-- ❌ WRONG - Inline INDEX syntax
CREATE TABLE table_name (
    id UUID PRIMARY KEY,
    name TEXT,
    INDEX idx_name (name)  -- This is INVALID
);
```

### **4. TRIGGER SYNTAX**
```sql
-- ✅ CORRECT - Always DROP first, then CREATE
DROP TRIGGER IF EXISTS update_table_updated_at ON table_name;
CREATE TRIGGER update_table_updated_at 
    BEFORE UPDATE ON table_name 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

### **5. RLS POLICY SYNTAX**
```sql
-- ✅ CORRECT - Always DROP first, then CREATE
DROP POLICY IF EXISTS "policy_name" ON table_name;
CREATE POLICY "policy_name" ON table_name
    FOR SELECT 
    TO authenticated
    USING (auth.uid() = user_id);
```

### **6. FUNCTION SYNTAX**
```sql
-- ✅ CORRECT - For auth functions
CREATE OR REPLACE FUNCTION function_name()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- function body
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```

---

## 📋 STANDARD TABLE TEMPLATE

```sql
-- ===============================================
-- TABLE_NAME TABLE
-- ===============================================

CREATE TABLE IF NOT EXISTS table_name (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- Core fields
    name TEXT NOT NULL,
    description TEXT,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'pending')),
    
    -- JSONB fields for flexible data
    metadata JSONB DEFAULT '{}'::jsonb,
    configuration JSONB DEFAULT '{}'::jsonb,
    
    -- Numeric fields with constraints
    score INTEGER CHECK (score >= 0 AND score <= 100),
    amount DECIMAL(10,2),
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT unique_user_name UNIQUE (user_id, name)
);
```

---

## 🔧 STANDARD MIGRATION STRUCTURE

```sql
-- ===============================================
-- MIGRATION_NAME
-- Date: YYYY-MM-DD
-- ===============================================

-- 1. CREATE TABLES
CREATE TABLE IF NOT EXISTS table_name (
    -- table definition
);

-- 2. CREATE INDEXES
CREATE INDEX IF NOT EXISTS idx_table_user_id ON table_name(user_id);
CREATE INDEX IF NOT EXISTS idx_table_created_at ON table_name(created_at);

-- 3. CREATE TRIGGERS
DROP TRIGGER IF EXISTS update_table_updated_at ON table_name;
CREATE TRIGGER update_table_updated_at 
    BEFORE UPDATE ON table_name 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 4. ENABLE RLS
ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;

-- 5. CREATE RLS POLICIES
DROP POLICY IF EXISTS "Users can view their own data" ON table_name;
CREATE POLICY "Users can view their own data" ON table_name
    FOR SELECT USING (auth.uid() = user_id);

-- 6. ENABLE REALTIME (after table creation)
ALTER PUBLICATION supabase_realtime ADD TABLE table_name;

-- 7. GRANT PERMISSIONS
GRANT ALL ON table_name TO authenticated;

-- 8. ADD COMMENTS
COMMENT ON TABLE table_name IS 'Description of table purpose';
```

---

## 🔒 RLS POLICY PATTERNS

### **Standard User Access Policies**
```sql
-- View own data
CREATE POLICY "Users can view their own data" ON table_name
    FOR SELECT USING (auth.uid() = user_id);

-- Insert own data
CREATE POLICY "Users can insert their own data" ON table_name
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Update own data
CREATE POLICY "Users can update their own data" ON table_name
    FOR UPDATE USING (auth.uid() = user_id);

-- Delete own data
CREATE POLICY "Users can delete their own data" ON table_name
    FOR DELETE USING (auth.uid() = user_id);
```

### **Service Role Access**
```sql
-- Service role full access
CREATE POLICY "Service role full access" ON table_name
    FOR ALL 
    TO service_role
    USING (true)
    WITH CHECK (true);
```

### **Anonymous Access (for pre-auth data)**
```sql
-- Anonymous can create (before signup)
CREATE POLICY "Anonymous can create data" ON table_name
    FOR INSERT 
    TO anon
    WITH CHECK (user_id IS NULL);
```

---

## ⚡ PERFORMANCE INDEXES

### **Standard Indexes for Every Table**
```sql
-- User-based queries
CREATE INDEX IF NOT EXISTS idx_table_user_id ON table_name(user_id);

-- Time-based queries
CREATE INDEX IF NOT EXISTS idx_table_created_at ON table_name(created_at);
CREATE INDEX IF NOT EXISTS idx_table_updated_at ON table_name(updated_at);

-- Status/state queries
CREATE INDEX IF NOT EXISTS idx_table_status ON table_name(status);

-- Search queries
CREATE INDEX IF NOT EXISTS idx_table_name ON table_name(name);
```

### **Composite Indexes**
```sql
-- Multi-column queries
CREATE INDEX IF NOT EXISTS idx_table_user_status ON table_name(user_id, status);
CREATE INDEX IF NOT EXISTS idx_table_user_created ON table_name(user_id, created_at DESC);
```

---

## 🔄 REALTIME CONFIGURATION

```sql
-- Enable realtime for tables (AFTER table creation)
ALTER PUBLICATION supabase_realtime ADD TABLE table_name;
ALTER PUBLICATION supabase_realtime ADD TABLE another_table;
```

---

## 📝 COMMON PATTERNS

### **JSONB Default Values**
```sql
-- Empty object
metadata JSONB DEFAULT '{}'::jsonb

-- Empty array
tags JSONB DEFAULT '[]'::jsonb

-- Complex default
settings JSONB DEFAULT '{
    "notifications": true,
    "theme": "light",
    "language": "en"
}'::jsonb
```

### **Check Constraints**
```sql
-- Status enums
status TEXT CHECK (status IN ('pending', 'active', 'completed', 'failed'))

-- Numeric ranges
score INTEGER CHECK (score >= 0 AND score <= 100)
rating INTEGER CHECK (rating >= 1 AND rating <= 5)

-- Boolean with default
is_active BOOLEAN DEFAULT true
```

### **Unique Constraints**
```sql
-- Single column
email TEXT UNIQUE NOT NULL

-- Multi-column
CONSTRAINT unique_user_name UNIQUE (user_id, name)
CONSTRAINT unique_session_user UNIQUE (user_id, session_id)
```

---

## 🚫 COMMON MISTAKES TO AVOID

### **❌ WRONG SYNTAX**
```sql
-- Wrong timestamp
created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()

-- Wrong data type
name VARCHAR(255)

-- Wrong index syntax
CREATE TABLE table_name (
    id UUID PRIMARY KEY,
    name TEXT,
    INDEX idx_name (name)  -- INVALID
);

-- Wrong trigger (missing DROP)
CREATE TRIGGER update_table_updated_at 
    BEFORE UPDATE ON table_name 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Wrong RLS policy (missing DROP)
CREATE POLICY "policy_name" ON table_name
    FOR SELECT USING (auth.uid() = user_id);
```

### **❌ WRONG ORDER**
```sql
-- Wrong: Realtime before table creation
ALTER PUBLICATION supabase_realtime ADD TABLE table_name;
CREATE TABLE table_name (...);

-- Wrong: Indexes before table creation
CREATE INDEX idx_table_name ON table_name(name);
CREATE TABLE table_name (...);
```

---

## ✅ VALIDATION CHECKLIST

Before applying any Supabase migration:

- [ ] All timestamps use `TIMESTAMPTZ`
- [ ] All text fields use `TEXT` (not `VARCHAR`)
- [ ] All indexes use `CREATE INDEX IF NOT EXISTS`
- [ ] All triggers have `DROP TRIGGER IF EXISTS` first
- [ ] All RLS policies have `DROP POLICY IF EXISTS` first
- [ ] Realtime is enabled AFTER table creation
- [ ] All functions use `SECURITY DEFINER SET search_path = public`
- [ ] All constraints use proper `CHECK` syntax
- [ ] All foreign keys reference `auth.users(id) ON DELETE CASCADE`
- [ ] All tables have `created_at` and `updated_at` timestamps

---

## 🎯 PRODUCTION READINESS

Every Supabase table must include:

1. **✅ Primary Key**: `id UUID DEFAULT gen_random_uuid() PRIMARY KEY`
2. **✅ User Association**: `user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE`
3. **✅ Timestamps**: `created_at` and `updated_at` with `TIMESTAMPTZ`
4. **✅ RLS Enabled**: `ALTER TABLE table_name ENABLE ROW LEVEL SECURITY`
5. **✅ RLS Policies**: Complete set of user access policies
6. **✅ Performance Indexes**: At minimum `user_id` and `created_at`
7. **✅ Updated Trigger**: Auto-update `updated_at` timestamp
8. **✅ Realtime Enabled**: For live updates
9. **✅ Permissions**: `GRANT ALL ON table_name TO authenticated`
10. **✅ Documentation**: Table and column comments

---

## 📚 REFERENCE EXAMPLES

### **Complete Working Example**
```sql
-- ===============================================
-- EXAMPLE_TABLE
-- ===============================================

CREATE TABLE IF NOT EXISTS example_table (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    metadata JSONB DEFAULT '{}'::jsonb,
    score INTEGER CHECK (score >= 0 AND score <= 100),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_user_name UNIQUE (user_id, name)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_example_table_user_id ON example_table(user_id);
CREATE INDEX IF NOT EXISTS idx_example_table_created_at ON example_table(created_at);
CREATE INDEX IF NOT EXISTS idx_example_table_status ON example_table(status);

-- Trigger
DROP TRIGGER IF EXISTS update_example_table_updated_at ON example_table;
CREATE TRIGGER update_example_table_updated_at 
    BEFORE UPDATE ON example_table 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- RLS
ALTER TABLE example_table ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own examples" ON example_table;
CREATE POLICY "Users can view their own examples" ON example_table
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own examples" ON example_table;
CREATE POLICY "Users can insert their own examples" ON example_table
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own examples" ON example_table;
CREATE POLICY "Users can update their own examples" ON example_table
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own examples" ON example_table;
CREATE POLICY "Users can delete their own examples" ON example_table
    FOR DELETE USING (auth.uid() = user_id);

-- Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE example_table;

-- Permissions
GRANT ALL ON example_table TO authenticated;

-- Comments
COMMENT ON TABLE example_table IS 'Example table demonstrating proper Supabase schema syntax';
COMMENT ON COLUMN example_table.user_id IS 'User who owns this record';
COMMENT ON COLUMN example_table.metadata IS 'Flexible JSON data storage';
```

---

**Last Updated:** January 25, 2025  
**Version:** 1.0  
**Status:** Production Ready  

This reference document should be consulted for ALL future Supabase database schema work to ensure consistency and prevent syntax errors.
