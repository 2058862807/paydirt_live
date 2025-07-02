-- PayDirt Live Revenue Management System Migration
-- Location: supabase/migrations/20241216150000_paydirt_revenue_system.sql

-- 1. Create custom types
CREATE TYPE public.activity_type AS ENUM ('payment', 'refund', 'subscription', 'invoice', 'transfer');
CREATE TYPE public.metric_type AS ENUM ('revenue', 'customers', 'transactions', 'conversion');

-- 2. Revenue metrics table
CREATE TABLE public.revenue_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    total_revenue DECIMAL(15,2) NOT NULL,
    revenue_change DECIMAL(5,2) NOT NULL,
    is_positive_change BOOLEAN NOT NULL DEFAULT true,
    period_start TIMESTAMPTZ NOT NULL,
    period_end TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Key metrics table
CREATE TABLE public.key_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    metric_type public.metric_type NOT NULL,
    title TEXT NOT NULL,
    value TEXT NOT NULL,
    change_percentage DECIMAL(5,2) NOT NULL,
    is_positive BOOLEAN NOT NULL DEFAULT true,
    icon_name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 4. Activities table
CREATE TABLE public.activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    activity_type public.activity_type NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    is_positive BOOLEAN NOT NULL DEFAULT true,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 5. Create indexes for performance
CREATE INDEX idx_revenue_metrics_created_at ON public.revenue_metrics(created_at DESC);
CREATE INDEX idx_key_metrics_type ON public.key_metrics(metric_type);
CREATE INDEX idx_key_metrics_updated_at ON public.key_metrics(updated_at DESC);
CREATE INDEX idx_activities_type ON public.activities(activity_type);
CREATE INDEX idx_activities_timestamp ON public.activities(timestamp DESC);

-- 6. Enable Row Level Security
ALTER TABLE public.revenue_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.key_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;

-- 7. Create RLS policies for public access (preview mode)
CREATE POLICY "public_read_revenue_metrics" ON public.revenue_metrics FOR SELECT TO public USING (true);
CREATE POLICY "public_read_key_metrics" ON public.key_metrics FOR SELECT TO public USING (true);
CREATE POLICY "public_read_activities" ON public.activities FOR SELECT TO public USING (true);

-- 8. Mock data for testing
DO $$
DECLARE
    revenue_id UUID := gen_random_uuid();
BEGIN
    -- Insert current revenue metrics
    INSERT INTO public.revenue_metrics (
        id, total_revenue, revenue_change, is_positive_change,
        period_start, period_end
    ) VALUES (
        revenue_id, 5420000.00, 12.5, true,
        date_trunc('month', CURRENT_TIMESTAMP),
        CURRENT_TIMESTAMP
    );

    -- Insert key metrics
    INSERT INTO public.key_metrics (metric_type, title, value, change_percentage, is_positive, icon_name) VALUES
        ('revenue'::public.metric_type, 'Monthly Revenue', '$5.42M', 12.5, true, 'trending_up'),
        ('customers'::public.metric_type, 'Active Customers', '1,247', 8.2, true, 'people'),
        ('transactions'::public.metric_type, 'Avg. Transaction', '$1,965', -2.1, false, 'payment'),
        ('conversion'::public.metric_type, 'Conversion Rate', '3.8%', 0.5, true, 'analytics');

    -- Insert recent activities
    INSERT INTO public.activities (activity_type, title, description, amount, is_positive, timestamp) VALUES
        ('payment'::public.activity_type, 'Payment Received', 'Invoice #INV-2024-001 - TechCorp Solutions', 15750.00, true, CURRENT_TIMESTAMP - INTERVAL '5 minutes'),
        ('refund'::public.activity_type, 'Refund Processed', 'Order #ORD-2024-156 - Premium Package', -2400.00, false, CURRENT_TIMESTAMP - INTERVAL '1 hour'),
        ('subscription'::public.activity_type, 'Subscription Renewal', 'Enterprise Plan - Global Industries Ltd', 8900.00, true, CURRENT_TIMESTAMP - INTERVAL '3 hours'),
        ('payment'::public.activity_type, 'Payment Received', 'Invoice #INV-2024-002 - StartupXYZ', 5200.00, true, CURRENT_TIMESTAMP - INTERVAL '6 hours'),
        ('invoice'::public.activity_type, 'Invoice Generated', 'Monthly billing - Corporate Account', 12500.00, true, CURRENT_TIMESTAMP - INTERVAL '8 hours');

END $$;

-- 9. Create function to update revenue metrics
CREATE OR REPLACE FUNCTION public.update_revenue_metrics()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Calculate total revenue from activities
    UPDATE public.revenue_metrics 
    SET 
        total_revenue = (
            SELECT COALESCE(SUM(amount), 0) 
            FROM public.activities 
            WHERE is_positive = true 
            AND timestamp >= date_trunc('month', CURRENT_TIMESTAMP)
        ),
        updated_at = CURRENT_TIMESTAMP
    WHERE period_start = date_trunc('month', CURRENT_TIMESTAMP);
END;
$$;

-- 10. Create cleanup function for test data
CREATE OR REPLACE FUNCTION public.cleanup_paydirt_test_data()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Delete test data in dependency order
    DELETE FROM public.activities WHERE description LIKE '%TechCorp%' OR description LIKE '%StartupXYZ%';
    DELETE FROM public.key_metrics WHERE title = 'Monthly Revenue';
    DELETE FROM public.revenue_metrics WHERE total_revenue = 5420000.00;
    
    RAISE NOTICE 'PayDirt test data cleaned up successfully';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Cleanup failed: %', SQLERRM;
END;
$$;