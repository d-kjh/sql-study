USE tuning;

-- 급여 → salaries
ALTER TABLE `급여` RENAME TO `salaries`;
ALTER TABLE `salaries`
  CHANGE COLUMN `사원번호` `emp_no` INT NOT NULL,
  CHANGE COLUMN `연봉` `salary` INT NOT NULL,
  CHANGE COLUMN `시작일자` `from_date` DATE NOT NULL,
  CHANGE COLUMN `종료일자` `to_date` DATE NOT NULL,
  CHANGE COLUMN `사용여부` `use_yn` CHAR(1) DEFAULT '';

-- 부서 → departments
ALTER TABLE `부서` RENAME TO `departments`;
ALTER TABLE `departments`
  CHANGE COLUMN `부서번호` `dept_no` CHAR(4) NOT NULL,
  CHANGE COLUMN `부서명` `dept_name` VARCHAR(40) NOT NULL,
  CHANGE COLUMN `비고` `remark` VARCHAR(40) DEFAULT NULL;

-- 부서관리자 → dept_manager
ALTER TABLE `부서관리자` RENAME TO `dept_manager`;
ALTER TABLE `dept_manager`
  CHANGE COLUMN `사원번호` `emp_no` INT NOT NULL,
  CHANGE COLUMN `부서번호` `dept_no` CHAR(4) NOT NULL,
  CHANGE COLUMN `시작일자` `from_date` DATE NOT NULL,
  CHANGE COLUMN `종료일자` `to_date` DATE NOT NULL;

-- 부서사원_매핑 → dept_emp
ALTER TABLE `부서사원_매핑` RENAME TO `dept_emp`;
ALTER TABLE `dept_emp`
  CHANGE COLUMN `사원번호` `emp_no` INT NOT NULL,
  CHANGE COLUMN `부서번호` `dept_no` CHAR(4) NOT NULL,
  CHANGE COLUMN `시작일자` `from_date` DATE NOT NULL,
  CHANGE COLUMN `종료일자` `to_date` DATE NOT NULL;

-- 사원 → employees
ALTER TABLE `사원` RENAME TO `employees`;
ALTER TABLE `employees`
  CHANGE COLUMN `사원번호` `emp_no` INT NOT NULL,
  CHANGE COLUMN `생년월일` `birth_date` DATE NOT NULL,
  CHANGE COLUMN `이름` `first_name` VARCHAR(14) NOT NULL,
  CHANGE COLUMN `성` `last_name` VARCHAR(16) NOT NULL,
  CHANGE COLUMN `성별` `gender` ENUM('M','F') NOT NULL,
  CHANGE COLUMN `입사일자` `hire_date` DATE NOT NULL;

-- 사원출입기록 → emp_access_logs (원본에는 없지만 보존 목적)
ALTER TABLE `사원출입기록` RENAME TO `emp_access_logs`;
ALTER TABLE `emp_access_logs`
  CHANGE COLUMN `순번` `id` INT NOT NULL AUTO_INCREMENT,
  CHANGE COLUMN `사원번호` `emp_no` INT NOT NULL,
  CHANGE COLUMN `입출입시간` `access_time` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHANGE COLUMN `입출입구분` `access_type` CHAR(1) NOT NULL,
  CHANGE COLUMN `출입문` `door` CHAR(1) DEFAULT NULL,
  CHANGE COLUMN `지역` `area` CHAR(1) DEFAULT NULL;

-- 직급 → titles
ALTER TABLE `직급` RENAME TO `titles`;
ALTER TABLE `titles`
  CHANGE COLUMN `사원번호` `emp_no` INT NOT NULL,
  CHANGE COLUMN `직급명` `title` VARCHAR(50) NOT NULL,
  CHANGE COLUMN `시작일자` `from_date` DATE NOT NULL,
  CHANGE COLUMN `종료일자` `to_date` DATE DEFAULT NULL;