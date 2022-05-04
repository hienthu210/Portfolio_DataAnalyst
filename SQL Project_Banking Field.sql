--Yêu cầu: 
--Xác định top 10 khách hàng có biến động tăng/giảm huy động vốn lớn nhất giữa 2 ngày dữ liệu liền nhau
--Bảng dữ liệu đích lưu kết quả tính toán là: DLY_BD_HDV_TOP_KH
--Các trường trong bảng bao gồm:
--       NgayBaoCao
--      ,LoaiBienDong
--      ,MaKH
--      ,HDV_NgayTruoc
--      ,HDV_NgayBaoCao
--      ,BienDong_HDV
--Nguồn dữ liệu là 2 bảng: 
--[DATA_MART].[dbo].[FactNonTermDeposits]
--[DATA_MART].[dbo].[FactTermDeposits]

--I. Tạo & chỉnh sửa thủ tục
ALTER PROCEDURE PROC_DLY_BD_HDV_TOP_KH
@NgayTruoc date, @NgayBaoCao date
AS
BEGIN

-- Bước 1. Tạo bảng đích, bảng trung gian và bảng pivot
PRINT '1. BAT DAU CHAY DU LIEU'
--CREATE TABLE REPORT_SYSTEM.dbo.DLY_BD_HDV_TOP_KH
--(
--NgayBaoCao date,
--LoaiBienDong nvarchar(50),
--MaKH varchar(25),
--HDV_NgayTruoc float,
--HDV_NgayBaoCao float,
--BienDong_HDV float
--)

--CREATE TABLE REPORT_SYSTEM.dbo.BD_HDV_TRUNGGIAN
--(
--MaKH varchar(25),
--HDV_NgayTruoc float,
--HDV_NgayBaoCao float,
--BienDong_HDV float
--)

--CREATE TABLE REPORT_SYSTEM.dbo.BD_HDV_PIVOT
--(
--MaKH_PV varchar(25),
--HDV_PV float
--)

-- Bước 2. Đưa chiều phân tích Mã KH vào bảng trung gian
PRINT '2. CHEN CHIEU PHAN TICH MaKH VAO BANG TRUNG GIAN'

TRUNCATE TABLE REPORT_SYSTEM.dbo.BD_HDV_TRUNGGIAN

INSERT INTO REPORT_SYSTEM.dbo.BD_HDV_TRUNGGIAN
(MaKH)
SELECT DISTINCT CIF
FROM
	(
	SELECT DISTINCT CIF
	FROM DATA_MART.dbo.FactTermDeposits
	WHERE TRANSACTION_DATE IN (@NgayTruoc, @NgayBaoCao)
	UNION
	SELECT DISTINCT CIF
	FROM DATA_MART.dbo.FactNonTermDeposits
	WHERE TRANSACTION_DATE IN (@NgayTruoc, @NgayBaoCao)
	) AS BANGTAM

--SELECT * FROM REPORT_SYSTEM.dbo.BD_HDV_TRUNGGIAN

-- 3. Tính số dư HDV theo khách hàng tại ngày trước
-- 3.1. Tính số dư HDV theo khách hàng tại ngày trước, lưu vào bảng pivot
PRINT '3.1. TINH HDV NGAY TRUOC TAI BANG PIVOT'

TRUNCATE TABLE REPORT_SYSTEM.dbo.BD_HDV_PIVOT

INSERT INTO REPORT_SYSTEM.dbo.BD_HDV_PIVOT
(MaKH_PV, HDV_PV)
SELECT 
		DISTINCT CIF, SUM(HDV_NgayTruoc) AS HDV_NgayTruoc_PV
FROM (
		SELECT DISTINCT CIF, SUM(BALANCE_QD) AS HDV_NgayTruoc
		FROM DATA_MART.dbo.FactNonTermDeposits
		WHERE TRANSACTION_DATE = @NgayTruoc
		GROUP BY CIF
		UNION
		SELECT DISTINCT CIF, SUM(BALANCE_QD) AS HDV_NgayTruoc
		FROM DATA_MART.dbo.FactTermDeposits
		WHERE TRANSACTION_DATE = @NgayTruoc
		GROUP BY CIF
	) AS NgayTruoc_BangTam
GROUP BY CIF

--SELECT * FROM REPORT_SYSTEM.dbo.BD_HDV_PIVOT

-- 3.2. Cập nhật số dư HDV theo khách hàng tại ngày trước vào bảng trung gian
PRINT '3.2. UPDATE HDV NGAY TRUOC VAO BANG TRUNG GIAN'
UPDATE B1 
SET B1.HDV_NgayTruoc = B2.HDV_PV
FROM	REPORT_SYSTEM.dbo.BD_HDV_TRUNGGIAN AS B1,
		REPORT_SYSTEM.dbo.BD_HDV_PIVOT AS B2
WHERE B1.MaKH = B2.MaKH_PV

--SELECT * FROM REPORT_SYSTEM.dbo.BD_HDV_TRUNGGIAN

-- 4. Tính số dư HDV theo khách hàng tại ngày báo cáo
-- 4.1. Tính số dư HDV theo khách hàng tại ngày báo cáo, lưu vào bảng pivot
PRINT '4.1. TINH HDV NGAY BAO CAO TAI BANG PIVOT'

TRUNCATE TABLE REPORT_SYSTEM.dbo.BD_HDV_PIVOT

INSERT INTO REPORT_SYSTEM.dbo.BD_HDV_PIVOT
(MaKH_PV, HDV_PV)
SELECT 
		DISTINCT CIF, SUM(HDV_NgayBaoCao) AS HDV_NgayBaoCao_PV
FROM (
		SELECT DISTINCT CIF, SUM(BALANCE_QD) AS HDV_NgayBaoCao
		FROM DATA_MART.dbo.FactNonTermDeposits
		WHERE TRANSACTION_DATE = @NgayBaoCao
		GROUP BY CIF
		UNION
		SELECT DISTINCT CIF, SUM(BALANCE_QD) AS HDV_NgayBaoCao
		FROM DATA_MART.dbo.FactTermDeposits
		WHERE TRANSACTION_DATE = @NgayBaoCao
		GROUP BY CIF
	) AS NgayBaoCao_BangTam
GROUP BY CIF

--SELECT * FROM REPORT_SYSTEM.dbo.BD_HDV_PIVOT

-- 4.2. Cập nhật số dư HDV theo khách hàng tại ngày báo cáo vào bảng trung gian
PRINT '4.2. UPDATE HDV NGAY BAO CAO VAO BANG TRUNG GIAN'

UPDATE B1 
SET B1.HDV_NgayBaoCao = B2.HDV_PV
FROM	REPORT_SYSTEM.dbo.BD_HDV_TRUNGGIAN AS B1,
		REPORT_SYSTEM.dbo.BD_HDV_PIVOT AS B2
WHERE B1.MaKH = B2.MaKH_PV

--SELECT * FROM REPORT_SYSTEM.dbo.BD_HDV_TRUNGGIAN

-- 5. Tính Biến động Huy động vốn tại bảng trung gian.
PRINT '5. UPDATE BIEN DONG HDV VAO BANG TRUNG GIAN'

UPDATE REPORT_SYSTEM.dbo.BD_HDV_TRUNGGIAN
SET BienDong_HDV = ISNULL(HDV_NgayBaoCao,0) - ISNULL(HDV_NgayTruoc,0)

--SELECT * FROM REPORT_SYSTEM.dbo.BD_HDV_TRUNGGIAN

-- 6. Lấy TOP 10 khách hàng có biến động tăng huy động vốn lớn nhất, lưu vào bảng kết quả đích cuối cùng
PRINT '6.1. XOA DU LIEU TAI BANG DICH'

DELETE FROM REPORT_SYSTEM.dbo.DLY_BD_HDV_TOP_KH
WHERE NgayBaoCao = @NgayBaoCao

PRINT '6.2. TINH TOP 10 KH TANG HDV LON NHAT VAO BANG DICH'

INSERT INTO REPORT_SYSTEM.dbo.DLY_BD_HDV_TOP_KH
(NgayBaoCao, LoaiBienDong, MaKH, HDV_NgayTruoc, HDV_NgayBaoCao, BienDong_HDV)
SELECT TOP 10
@NgayBaoCao AS NgayBaoCao, 'TANG_HDV_MAX' AS LoaiBienDong,
MaKH, HDV_NgayTruoc, HDV_NgayBaoCao, BienDong_HDV
FROM REPORT_SYSTEM.dbo.BD_HDV_TRUNGGIAN
WHERE BienDong_HDV > 0
ORDER BY BienDong_HDV DESC

--7. Lấy TOP 10 khách hàng có biến động giảm huy động vốn lớn nhất, lưu vào bảng kết quả đích cuối cùng
PRINT '7. TINH TOP 10 KH GIAM HDV LON NHAT VAO BANG DICH'

INSERT INTO REPORT_SYSTEM.dbo.DLY_BD_HDV_TOP_KH
(NgayBaoCao, LoaiBienDong, MaKH, HDV_NgayTruoc, HDV_NgayBaoCao, BienDong_HDV)
SELECT TOP 10
@NgayBaoCao AS NgayBaoCao, 'GIAM_HDV_MAX' AS LoaiBienDong,
MaKH, HDV_NgayTruoc, HDV_NgayBaoCao, BienDong_HDV
FROM REPORT_SYSTEM.dbo.BD_HDV_TRUNGGIAN
WHERE BienDong_HDV < 0
ORDER BY BienDong_HDV

-- Xem kết quả cuối cùng
--SELECT * FROM REPORT_SYSTEM.dbo.DLY_BD_HDV_TOP_KH

PRINT '8. HOAN THANH CHAY DU LIEU'

END

--II. Chạy thủ tục tự động cho các ngày dữ liệu
EXEC REPORT_SYSTEM.dbo.PROC_DLY_BD_HDV_TOP_KH '2017-09-22', '2017-09-23'
EXEC REPORT_SYSTEM.dbo.PROC_DLY_BD_HDV_TOP_KH '2017-09-23', '2017-09-25'
EXEC REPORT_SYSTEM.dbo.PROC_DLY_BD_HDV_TOP_KH '2017-09-25', '2017-09-26'
EXEC REPORT_SYSTEM.dbo.PROC_DLY_BD_HDV_TOP_KH '2017-09-26', '2017-09-27'
EXEC REPORT_SYSTEM.dbo.PROC_DLY_BD_HDV_TOP_KH '2017-09-27', '2017-09-28'
EXEC REPORT_SYSTEM.dbo.PROC_DLY_BD_HDV_TOP_KH '2017-09-28', '2017-09-29'

---Kiểm tra kết quả
SELECT *
FROM REPORT_SYSTEM.dbo.DLY_BD_HDV_TOP_KH
WHERE NgayBaoCao BETWEEN '2017-09-23' AND '2017-09-29'
