-- DEV ONLY (RIT-US-04, AB#13; dev seed users approved by Melani Shibu on 11/19/2026; departments RIT-US-06, AB#48).
-- Loaded only by the dev profile (spring.flyway.locations in application-dev.yml). Never in production or by the default test
-- profile; AuthLoginIT adds this location explicitly. A production first-admin setup is future work.
--
-- Shared dev password: ResolveIT-Dev-2026 (documented in the README; not a real secret).
-- Stored as a BCrypt hash (cost 10). Re-running is safe: existing users keep everything except their department,
-- which is set to the seed value.

INSERT INTO identity.app_user (id, email, display_name, role, password_hash, active, department)
VALUES
    ('00000000-0000-4000-8000-000000000001', 'admin@resolveit.local',     'ResolveIT Admin', 'ADMIN',
     '$2a$10$vdxq/oWjuLrsVHtlSFeOk.kkJkbEN3UjE2aMDNauexaXvVsnVtv3u', TRUE,  'IT'),
    ('00000000-0000-4000-8000-000000000002', 'agent1@resolveit.local',    'Agent One',       'SUPPORT_AGENT',
     '$2a$10$vdxq/oWjuLrsVHtlSFeOk.kkJkbEN3UjE2aMDNauexaXvVsnVtv3u', TRUE,  'IT Support'),
    ('00000000-0000-4000-8000-000000000003', 'agent2@resolveit.local',    'Agent Two',       'SUPPORT_AGENT',
     '$2a$10$vdxq/oWjuLrsVHtlSFeOk.kkJkbEN3UjE2aMDNauexaXvVsnVtv3u', FALSE, 'IT Support'),
    ('00000000-0000-4000-8000-000000000004', 'employee1@resolveit.local', 'Employee One',    'EMPLOYEE',
     '$2a$10$vdxq/oWjuLrsVHtlSFeOk.kkJkbEN3UjE2aMDNauexaXvVsnVtv3u', TRUE,  'Finance'),
    ('00000000-0000-4000-8000-000000000005', 'employee2@resolveit.local', 'Employee Two',    'EMPLOYEE',
     '$2a$10$vdxq/oWjuLrsVHtlSFeOk.kkJkbEN3UjE2aMDNauexaXvVsnVtv3u', TRUE,  'Human Resources')
ON CONFLICT (email) DO UPDATE SET department = EXCLUDED.department;
