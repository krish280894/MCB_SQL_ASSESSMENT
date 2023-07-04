create or replace procedure ORDERS_SUMMARY
	AS  
	 c1 SYS_REFCURSOR;  
	BEGIN 
	  open c1 for
	SELECT "Order Reference", "Order Period", "Supplier Name", "Order Total Amount", "Order Status", "Invoice Reference", "Invoice Total Amount", "Action" FROM (
	SELECT DISTINCT LTRIM(REPLACE(B.ORDER_REF,'PO',''),'0') AS "Order Reference", 
	TO_CHAR(B.ORDER_DATE,'MON-YY') AS "Order Period", 
	INITCAP(C.SUPPLIER_NAME) AS "Supplier Name",
	TO_CHAR(B.ORDER_TOTAL_AMOUNT,'99,999,990.00') AS "Order Total Amount", 
	B.ORDER_STATUS AS "Order Status",
	A.INVOICE_REFERENCE AS "Invoice Reference",
	TO_CHAR(INVOICE_AMOUNT,'99,999,990.00') AS "Invoice Total Amount",
	Action(B.ORDER_ID) AS "Action",
	ORDER_DATE
	FROM XXBCM_INVOICE A 
	INNER JOIN XXBCM_ORDER B ON B.ORDER_ID = A.ORDER_ID
	INNER JOIN XXBCM_SUPPLIER C ON C.SUPPLIER_ID = B.SUPPLIER_ID
	ORDER BY B.ORDER_DATE DESC
	);
	 DBMS_SQL.RETURN_RESULT(c1);

	END;
	/

create or replace FUNCTION Action(v_ORDER_ID IN VARCHAR2)
	RETURN VARCHAR2 IS
	       v_counter NUMBER := 0;
	       v_rowcount NUMBER := 0;
	       v_checkPaid NUMBER := 0;
	       v_pending NUMBER :=0;
	       v_blank NUMBER := 0; 
	       v_OUTPUT VARCHAR(20);
	       v_STATUS VARCHAR2(20);
	BEGIN
		SELECT COUNT(*) INTO v_rowcount FROM XXBCM_INVOICE WHERE ORDER_ID=V_ORDER_ID;
	    
		FOR k IN 1..v_rowcount LOOP
			WITH selection_criteria AS (
				SELECT INVOICE_STATUS, ROW_NUMBER() OVER (ORDER BY ORDER_ID) AS RNUM
				FROM XXBCM_INVOICE
				WHERE ORDER_ID=V_ORDER_ID
			) 
			SELECT INVOICE_STATUS INTO v_STATUS
			FROM selection_criteria
			WHERE RNUM = k; 
			
			v_counter := v_counter + 1;
			IF v_STATUS = 'Paid' THEN v_checkPaid:=v_checkPaid+1;
			ELSIF v_STATUS = 'Pending' THEN v_pending := 1;
			ELSIF v_STATUS IS NULL THEN v_blank := 1;
			END IF;
			EXIT WHEN v_counter = v_rowcount;
	    END LOOP;
	    
		IF v_checkPaid = v_rowcount THEN v_OUTPUT := 'OK';
	    END IF;
	    IF v_pending = 1 THEN v_OUTPUT := 'To follow up';
	    END IF;
	    IF v_blank = 1 THEN v_OUTPUT := ' To verify';
	    END IF;
	RETURN v_OUTPUT;
	END;
	/