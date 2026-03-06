-- Beverly Hills Cop — Seed Data
-- Manual seed for Phase 1 validation

-- Contacts
INSERT INTO contacts (id, name, email, company, role) VALUES
    ('a0000000-0000-0000-0000-000000000001', 'Alex Demo', 'alex@example.com', 'Zeon', 'founder'),
    ('a0000000-0000-0000-0000-000000000002', 'Maria Contractor', 'maria@freelance.dev', NULL, 'contractor'),
    ('a0000000-0000-0000-0000-000000000003', 'Acme Hosting Inc', 'billing@acmehost.com', 'Acme Hosting', 'vendor');

-- Projects
INSERT INTO projects (id, name, status, priority, owner_id, description) VALUES
    ('b0000000-0000-0000-0000-000000000001', 'Zeon Platform', 'active', 'critical',
     'a0000000-0000-0000-0000-000000000001', 'Main product platform build'),
    ('b0000000-0000-0000-0000-000000000002', 'Beverly Hills Cop', 'active', 'high',
     'a0000000-0000-0000-0000-000000000001', 'Personal ops system'),
    ('b0000000-0000-0000-0000-000000000003', 'Client Website Redesign', 'active', 'medium',
     'a0000000-0000-0000-0000-000000000002', 'Freelance project — redesign for client');

-- Payments
INSERT INTO payments (description, amount, currency, direction, status, due_date, source, project_id, contact_id) VALUES
    ('Hosting — March 2026', 120.00, 'EUR', 'outbound', 'pending',
     '2026-03-15', 'invoice', 'b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000003'),
    ('Contractor payment — Feb sprint', 3200.00, 'EUR', 'outbound', 'overdue',
     '2026-03-01', 'invoice', 'b0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000002'),
    ('Client deposit received', 5000.00, 'EUR', 'inbound', 'paid',
     '2026-02-20', 'bank transfer', 'b0000000-0000-0000-0000-000000000003', NULL);

-- Events
INSERT INTO events (title, event_type, event_date, confirmed, project_id) VALUES
    ('Zeon v2 launch deadline', 'deadline', '2026-03-20 18:00:00+01', false,
     'b0000000-0000-0000-0000-000000000001'),
    ('Contractor sync call', 'meeting', '2026-03-08 14:00:00+01', true,
     'b0000000-0000-0000-0000-000000000003'),
    ('Ops system Phase 1 review', 'milestone', '2026-03-12 10:00:00+01', false,
     'b0000000-0000-0000-0000-000000000002');

-- Notes
INSERT INTO notes (entity_type, entity_id, text) VALUES
    ('project', 'b0000000-0000-0000-0000-000000000001', 'Need to finalize auth flow before launch'),
    ('payment', (SELECT id FROM payments WHERE description LIKE '%Contractor%'), 'Maria sent reminder on Feb 28 — pay ASAP');
