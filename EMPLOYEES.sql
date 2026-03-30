

USE employee_schedule;
DROP TABLE IF EXISTS schedules;

CREATE TABLE schedules (
    schedule_id INT AUTO_INCREMENT PRIMARY KEY,
    employee_id INT,
    employee_name VARCHAR(100),
    schedule_date VARCHAR(20),
    day_name VARCHAR(15),
    schedule_start VARCHAR(20),
    schedule_end VARCHAR(20),
    lunch_start VARCHAR(20),
    lunch_end VARCHAR(20),
    status VARCHAR(20),
    week_number INT,
    is_working INT,
    is_absent INT,
    is_off INT,
    shift_category VARCHAR(25)
);

LOAD DATA LOCAL INFILE 'C:/Users/Ahmad/OneDrive/Desktop/schedule_data.csv'
INTO TABLE schedules
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(employee_id, employee_name, schedule_date, day_name,
 schedule_start, schedule_end, lunch_start, lunch_end,
 status, week_number, is_working, is_absent, is_off, shift_category);

SELECT COUNT(*) FROM schedules;

SET GLOBAL local_infile = 1;

SELECT *
FROM schedules;

SELECT COUNT(*) FROM schedules;
-- لازم يطلع 20460

SELECT status, COUNT(*) AS cnt 
FROM schedules 
GROUP BY status;
-- On duty = 13684, Off = 6084, Absent/Leave = 692


-- ============================================================
-- Employee Schedule Analysis — Single Table Version
-- مشروع تحليل جداول عمل الموظفين — يناير 2026
-- ============================================================
-- Works with ONE table: schedules (all columns including employee_name)
-- No JOINs needed — everything runs directly
-- ============================================================


-- ============================================================
-- PART 1: VERIFY YOUR DATA IMPORTED CORRECTLY
-- الجزء الأول: تأكد أن البيانات دخلت صح
-- ============================================================


-- Check 1: Total rows (must be 20460)
SELECT COUNT(*) AS total_records FROM schedules;

-- Check 2: Status breakdown
SELECT status, COUNT(*) AS cnt FROM schedules GROUP BY status;
-- Expected: On duty = 13684, Off = 6084, Absent/Leave = 692

-- Check 3: Unique employees (must be 660)
SELECT COUNT(DISTINCT employee_id) AS total_employees FROM schedules;

-- Check 4: Every day should have 660 records
SELECT schedule_date, COUNT(*) AS records
FROM schedules
GROUP BY schedule_date
HAVING COUNT(*) != 660;
-- If this returns EMPTY = PASS (all days have 660)

-- Check 5: Sum check
SELECT 
    SUM(is_working) + SUM(is_off) + SUM(is_absent) AS computed,
    COUNT(*) AS actual,
    CASE WHEN SUM(is_working) + SUM(is_off) + SUM(is_absent) = COUNT(*) 
         THEN 'PASS' ELSE 'FAIL' END AS result
FROM schedules;


-- ============================================================
-- PART 2: KPI OVERVIEW — All key metrics in one query
-- الجزء الثاني: نظرة عامة على المؤشرات
-- ============================================================

SELECT 
    COUNT(*) AS total_records,
    COUNT(DISTINCT employee_id) AS total_employees,
    COUNT(DISTINCT schedule_date) AS total_days,
    SUM(is_working) AS on_duty,
    SUM(is_off) AS off_count,
    SUM(is_absent) AS absent,
    ROUND(SUM(is_working) * 100.0 / COUNT(*), 1) AS attendance_pct,
    ROUND(SUM(is_absent) * 100.0 / COUNT(*), 1) AS absence_pct
FROM schedules;
-- Expected: 20460 | 660 | 31 | 13684 | 6084 | 692 | 66.9% | 3.4%


-- ============================================================
-- PART 3: DAILY SUMMARY
-- الجزء الثالث: الملخص اليومي (نفس شيت Daily Summary في Excel)
-- ============================================================

SELECT 
    schedule_date,
    day_name,
    SUM(is_working) AS on_duty,
    SUM(is_off) AS off_count,
    SUM(is_absent) AS absent,
    COUNT(*) AS total,
    ROUND(SUM(is_working) * 100.0 / COUNT(*), 1) AS attendance_rate,
    ROUND(SUM(is_absent) * 100.0 / COUNT(*), 1) AS absence_rate
FROM schedules
GROUP BY schedule_date, day_name
ORDER BY schedule_date;
-- 31 rows — one per day


-- ============================================================
-- PART 4: WEEKDAY ANALYSIS
-- الجزء الرابع: تحليل أيام الأسبوع (نفس شيت Weekday Analysis)
-- ============================================================

SELECT 
    day_name,
    SUM(is_working) AS on_duty,
    SUM(is_off) AS off_count,
    SUM(is_absent) AS absent,
    COUNT(*) AS total,
    ROUND(SUM(is_working) * 100.0 / COUNT(*), 1) AS attendance_rate,
    ROUND(SUM(is_absent) * 100.0 / COUNT(*), 1) AS absence_rate
FROM schedules
GROUP BY day_name
ORDER BY FIELD(day_name, 'Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday');
-- Wednesday = best (70.0%), Friday = worst absence (141)


-- ============================================================
-- PART 5: SHIFT DISTRIBUTION
-- الجزء الخامس: توزيع الشيفتات (نفس شيت Shift Distribution)
-- ============================================================

SELECT 
    schedule_start AS shift_time,
    COUNT(*) AS assignments,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS pct_of_total
FROM schedules
WHERE status = 'On duty'
GROUP BY schedule_start
ORDER BY assignments DESC;
-- 07:00 is the most common with 3975 assignments


-- Shift categories
SELECT 
    shift_category,
    COUNT(*) AS cnt,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS pct
FROM schedules
WHERE status = 'On duty'
GROUP BY shift_category
ORDER BY cnt DESC;
-- Morning 66.6% | Night 20.5% | Afternoon 12.9%


-- ============================================================
-- PART 6: WEEKLY TRENDS
-- الجزء السادس: الاتجاهات الأسبوعية (نفس شيت Weekly Trends)
-- ============================================================

SELECT 
    week_number,
    SUM(is_working) AS on_duty,
    SUM(is_absent) AS absent,
    SUM(is_off) AS off_count,
    COUNT(*) AS total,
    ROUND(SUM(is_working) * 100.0 / COUNT(*), 1) AS attendance_rate
FROM schedules
GROUP BY week_number
ORDER BY week_number;
-- Week 1: 237 absences → Week 5: 70 absences (70% improvement!)


-- ============================================================
-- PART 7: EMPLOYEE ABSENCE RANKING
-- الجزء السابع: ترتيب الموظفين حسب الغياب
-- ============================================================

SELECT 
    employee_id,
    employee_name,
    SUM(is_absent) AS absence_days,
    ROUND(SUM(is_absent) * 100.0 / 31, 1) AS absence_rate_pct
FROM schedules
GROUP BY employee_id, employee_name
HAVING SUM(is_absent) > 0
ORDER BY absence_days DESC
LIMIT 20;
-- Top 5 employees were absent ALL 31 days (100%!)




-- ============================================================
-- ADVANCED — Subquery (Above-Average Absentees)
-- الجزء الخامس عشر: الموظفين اللي غيابهم أعلى من المتوسط
-- ============================================================

SELECT 
    employee_name,
    SUM(is_absent) AS absences
FROM schedules
GROUP BY employee_name
HAVING SUM(is_absent) > (
    SELECT AVG(emp_abs) FROM (
        SELECT SUM(is_absent) AS emp_abs 
        FROM schedules GROUP BY employee_id
    ) sub
)
ORDER BY absences DESC;

-- Inner subquery calculates average absence per employee
-- Outer query filters those ABOVE that average
-- HAVING (not WHERE) because we filter on GROUP BY result


-- ============================================================
--  ADVANCED — Pivot Query (Attendance by Week × Day)
-- الجزء السادس عشر: جدول محوري — حضور كل أسبوع × كل يوم
-- ============================================================

SELECT 
    week_number,
    SUM(CASE WHEN day_name = 'Sunday' THEN is_working END) AS sun,
    SUM(CASE WHEN day_name = 'Monday' THEN is_working END) AS mon,
    SUM(CASE WHEN day_name = 'Tuesday' THEN is_working END) AS tue,
    SUM(CASE WHEN day_name = 'Wednesday' THEN is_working END) AS wed,
    SUM(CASE WHEN day_name = 'Thursday' THEN is_working END) AS thu,
    SUM(CASE WHEN day_name = 'Friday' THEN is_working END) AS fri,
    SUM(CASE WHEN day_name = 'Saturday' THEN is_working END) AS sat
FROM schedules
GROUP BY week_number
ORDER BY week_number;

-- SQL has no built-in PIVOT like Excel
-- SUM(CASE WHEN...) converts rows into columns
-- Very common interview question!


-- ============================================================
--  COMPREHENSIVE KPI QUERY
-- الجزء السابع عشر: كل المؤشرات في استعلام واحد
-- ============================================================

SELECT 
    'January 2026' AS period,
    COUNT(DISTINCT employee_id) AS employees,
    COUNT(*) AS total_records,
    SUM(is_working) AS on_duty,
    SUM(is_absent) AS absent,
    ROUND(SUM(is_working) * 100.0 / COUNT(*), 1) AS attendance_pct,
    ROUND(SUM(is_absent) * 100.0 / COUNT(*), 1) AS absence_pct,
    (SELECT day_name FROM schedules 
     GROUP BY day_name ORDER BY SUM(is_absent) DESC LIMIT 1) AS worst_day,
    (SELECT schedule_start FROM schedules 
     WHERE status = 'On duty' 
     GROUP BY schedule_start ORDER BY COUNT(*) DESC LIMIT 1) AS top_shift
FROM schedules;


