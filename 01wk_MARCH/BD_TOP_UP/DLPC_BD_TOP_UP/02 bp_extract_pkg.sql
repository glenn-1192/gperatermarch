CREATE OR REPLACE PACKAGE BODY bp_extract_pkg
/*
    REVISION HISTORY
        v1.4.4 by gperater on February 28, 2024 --CR BD TOP UP for uat testing please notify me if theres a change and possible deployment
               purpose of change : new function created to get the amount of the BD SA in calc lines to be displayed on the bill for CR :  BD TOP UP
                                   get_bd_bseg_amt
                                   new procedure insert_bd_bseg created for getting BD SA details and insertion to bp_details
                                   new config added in bp_detail_codes BDSA
                                   revised proc extract_bills : inserted the new function created get_bd_bseg_amt insertion to bp_details 
                                                                and procedure insert_bd_bseg
                                   revised proc get_net_bill_amt2 enabled the condition of sa_type_cd = D-BILL this is to include the BD SA amount
                                   in the Total Amount Due sum
               affected objects : new : get_bd_bseg_amt, insert_bd_bseg
                                  old : extract_bills, get_net_bill_amt2
               remarks          : revised procedure extract_bills & get_net_bill_amt2 and new function created get_bd_bseg_amt
        v1.4.3 by gperater on January 11, 2024
               purpose of change : revised populate_bp_bir_2013 and add a separate sum computation for FCT code (Franchise Tax Local)
                                   this change would let the LFT to be included in the Vatable Sales instead of Vat Exempt as per existing source
               affected objects  : populate_bp_bir_2013
               remarks           : revised procedure populate_bp_bir_2013
        v1.4.2 by rreston on Sept 12, 2023
              purpose of change : remove 0 amounts
               affected objects : remove_zero_line_amt
               remarks : add new code to remove 0 amounts

        v1.4.1 by gperater on August 18, 2023
               purpose of change : newly created procedure to remove zero amounts on bp details
               affected objects : new, remove_zero_line_amt
               remarks : newly created proc to remove zero amounts on bp details to prevent the double page during extraction
        v1.4.0 by rreston on July 02, 2023
             purpose of change : additional procedure
             affected objects  : new, retrieve_billing_address
             remarks           : route to the correct source for billing address as per bpa

        v1.4.0 by gmepieza on June 02, 2023
             purpose of change : additional rate component for uc-me true up 2013  added to get the exact line_rate on the bill
             affected objects  : old, adjust_uc_mes
             remarks           : updated proc, added new rate components for uc-me true up for getting the line_rate in NPC-SPUG
        v1.3.9 by gmepieza on December 20, 2022
             purpose of change : for tagging the ebill text accounts
             affected objects  : new:get_text_only_tag
                                 old:extract_bills
             remarks           : new:added a function for tagging the ebill text accounts
                                 old:alter table bp_headers, view bp_query  and add new column txt_only
                                 old:revise the old procedure extract_bills and inject the new function

        v1.3.8 by JTAN on October 10, 2022
               Purpose of Change : To avoid a redundant display of the line on the bill, so we summarize the adjustment for PBR Guaranteed Service Level
               Affected Objects : extract_bills
               Remarks          : additional procedure,summarize_gsl

        v1.3.7 by GMEPIEZA on September 6, 2022
               Purpose of Change : Added a query for the new line UC ME TRUE UP and lump it together with UC-ME NPC SPUG
               Affected Objects : additional query: adjust_uc_mes, updated the groupings for getting the UC-ME's
               Remarks          : updated procedure, adjust_uc_mes -- CM 1578 DLPC UC ME TRUE UP

        v1.3.6 by JTAN on April 05, 2022
             Purpose of Change : To correct the total amount for BIR_2306, BIR_2307 and senior citizen discount or pwd discount and other related process
             Affected Objects  : all process/objects using the CI_BSEG table
             Remarks           : new:added condition for all process using the CI_BSEG table (BSEG_STAT_FLG in ('50','70'))
                                 old:revise condition for other existing process from ((BSEG_STAT_FLG = '50') to (BSEG_STAT_FLG in ('50','70')))

        v1.3.5 by LGYAP on August 10, 2020
             Purpose of Change : fix surcharge adjustments coming from other SAs
             Affected Objects  : additional paramater: get_lpc, new: adjust_dr_cr_line
             Remarks           : additional procedure,adjust_pa_arrears

        v1.3.4 by HNLimpio on August 10, 2020
             Purpose of Change : to cater Payment Arrangement Arrears for Batch
             Affected Objects  : adjust_pa_arrears
             Remarks           : additional procedure,adjust_pa_arrears

        v1.3.3 by LGYAP on April 30, 2020
             Purpose of Change : ECQ related enhancements
             Affected Objects  : extract_bills
             Remarks           : additional procedure,add_ecq_info

        v1.3.2 by jlcomeros on Aug 28, 2018
            Purpose of Change : to support new version of BDS
            Affected Objects  : GET_BDMSGR
            Remarks           : get data first from CHAR_VAL otherwise from ADHOC_CHAR_VAL

        v1.3.1 by hnlimpio on May 02, 2018
            Purpose of Change : to exclude the display of vat npc/psalm adjustment but include the computation on the vat gen - total
            Affected Objects  : insert_bp_details
            Remarks           : to hide negative amounts of vat npc/psalm adjustment

        v1.3.1 by AOCARCALLAS on March 31, 2017
            Purpose of Change : To correct the BIR 2306 computation.
            Affected Objects  : old:populate_bp_bir_2013
            Remarks           : Correction remove condition (and calc_ln.descr_on_bill <> 'BIR 2306 PPVAT - Transco'):
                                 -- for total amount of BIR 2306

        v1.3.0 by LGYAP on March 03, 2017
            Purpose of Change : This is to correct computation in BIR 2013 portion
            Affected Objects  : populate_bp_bir_2013
            Remarks           : Part of BIR Compliance

        v1.2.1 16-FEB-2017 AOCARCALLAS
            Purpose of Change : There's a discrepancy on the TOTAL VAT because bseg_stat_flg was not include in the condition.
            Affected Objects  : old:insert_bp_details
            Remarks           : Issue was discovered in request id 102967.

        revised by : lgyap
        revised on : dec 20, 2016
                   : new function, get_tin

   revised by : lgyap
   revised on : nov 11, 2016
   remarks    : new function, get_business_style - for business style
                new procedure, retrieve_business_address - for business address

   revised by : aocarcallas
   revised on : August 26,2016
   remarks    : added procedure bill_print_sweeper
              : bill extraction for the last two days (complete date - 2).

   revised by: lgyap
   revised on: June 30, 2016
   remarks   : additional procedures  for CAS 2
               such as :
                   populate_bp_bir_2013
   revised by: bcconejos
   revised on: June 30, 2016
   remarks   : revise procedure INSERT_FLT_CONSUMPTION_HIST
               - extract 13 consumption history

   revised by: bcconejos
   revised on: June 30, 2016
   remarks   : bpx db has been separated from cisadm db, object types and collection types
               cannot cross db links. transfered Insert Meter Details procedure to cisadm
               as cm_bp_extract_util_pkg

   revised on : Nov. 27, 2014
   revised by : bcconejos
   remarks : modify source for getting location code
             redirected query from db link to
             query using materialized view for virtuoso wam locators

   revised on : Nov. 26, 2014
   revised by : bcconejos
   remarks : modify source for getting location code
             added condition acct_status = 'Active' on 1st query

   revised on : Oct. 24, 2014
   revised by : bcconejos
   remarks : modify source for getting location code

   version 2014.07.22
   revised on : july 22, 2014
   revised by : lgyap
   remarks    : additional: procedure for populating bill message parameters

   version 2014.04.07.01
   revised on : apr 07, 2014
   revised by : lgyap
   remarks    : revision of procedrue adjust_uc_MEs,
                new grouping of uc

   version 2014.03.25.01
   revised on : mar 25, 2014
   revised by : lgyap
   remarks    : revision of procedure adjust_uc_MEs,
                adding exception handler that will bypass and log the erroneous bills

   version 2014.01.29.01
   revised on : jan 29, 2014
   revised by : lgyap
   remarks    : revision of the procedure adjust_uc_MEs for the new calc, uc missionary electrification 3

   version 2014.01.07.01
   revised on : jan 07, 2014
   remarks    : new procedure for the adjustment of missionary electrification details, adjust_uc_MEs

   version 1.4.3
   revised by : lgyap
   revised on : nov 28, 2013
   remarks    : revision in procedure insert_adjustments for the net metering transfer adjustment
                additional condition @ line 2922, "sa.sa_type_cd != 'NET-E'"

   version 1.4.2
   revised by : lgyap
   revised on : may 22, 2013
   remarks    : revision in insert_consumption_hist for the implementation of 13months in the bill graph

   version 1.4.1
   revised by : bcc
   revised on : sep 03, 2012
   remarks    : fixed issue of "do not extract"
                value of l_bph.no_batch_prt_sw was not initialized

   version 1.4.1
   revised by : bcc
   revised on : jul 10, 2012
   remarks    : added column to bp_headers (no_batch_prt_sw)
                this is a flag to determine if the bill was
                tagged as "do not extract". the bill must not
                be included in the pdf if it is flagged as "do not extract"

   version 1.4.0
   revised by : bcc
   revised on : jul 05, 2012
   remarks    : modified get_overdue_amt2
                return 0 if current_bill amt is less than 0

   version 1.3.9
   revised by : bcc
   revised on : may 25, 2012
   remarks    : modified archiving of bills procedure

   version 1.3.8
   revised by : lgyap
   revised on : may 02, 2012
   remarks    : revision in procedure extract bills for the billed_kwhr_cons for flatrate
                new procedure insert_flt_consumption_hist
                new procedure retrieve_flt_info for flatrate info

   version 1.3.7
   revised by : lgyap
   revised on : april 26, 2012
   remarks    : revision in procedure insert_bp_details for the line rate of Senior Citizen Discount

   version 1.3.6
   revised by : lgyap
   revised on : april 17, 2012
   remarks : include code MFX-R for lifeline subsidy discount fix

   version 1.3.5
   revised by : lgyap
   revised on : april 16, 2012
   remarks    : change linre rate for SENIOR CITIZEN to "5%"   DISCOUNT

   version 1.3.4
   revised by: bcc
   revised on: april 16, 2012
   remarks: change line rate for LPC to "2%"

   version 1.3.3
   revised by: bcc
   revised on: april 12, 2012
   remarks: added functionality to archive bills
            if a request to extract a bill that already exists
            in the archive tables is received, the extract_bill
            will get it from the archived tables

   version 1.3.2
   revised by : bcc
   revised on : march 27, 2012
   remarks: modified the retrieval of bill message code
            it will retrieve the message with the highest priority

   version 1.3.1
   revised by : lgyap
   remarks    : revised procedure extract_bills.
                increment batch_nbr when parameter bill_id is null

   version 1.3.0
   revised by : bcc
   remarks    : when retrieving net bill amt, it will not include deposits, exception bill dep
                when retrieving previous balance, it will not include deposits
                when getting consumption hist, retrieve only 12months
                if LPC base amount is null, return a derived amount

   version 1.2.9
   revised on : feb 14, 2012
   revised by : bcc
   remarks    : allow previous amount to be negative

   version 1.2.8
   revised on : feb 13, 2012
   revised by : bcc
   remarks    : group Prepaid VAT Output adjustments as 1 line

   version 1.2.7
   revised on : feb 07, 2012
   revised by : bcc
   remarks    : breakdown amount per adjustment type after the current bill amount
              : include in previous balance, the previous balances of Payment Arrangements

   version 1.2.6
   revised on : jan 19, 2012
   revised by : lgyap
   remarks    : revision in procedure insert_consumption_hist, to sum up consumption of the same month

   version 1.2.5
   revised on : nov 25, 2011
   revised by : lgyap
   remarks    : revision in procedure insert_consumption_hist, to include inactive electric SA's billing history

   version 1.2.4
   revised on : nov 17,2011
   revised by : bcc
   remarks    : get overdue amount even if bill is green

   version 1.2.3
   revised on : nov 16,2011
   revised by : lgyap
   remarks    : revision in function extract_bills procedure for the bug found in retrieving batch cycle value

   version 1.2.2
   revised on : nov 14, 2011
   revised by : lgyap
   remarks    : additional functions get_par_month

   version 1.2.1
   revised on : oct 17,2011
   revised by : lgyap
   remarks    : revised extract_bills procedure
                for the following labels of TOTAL AMOUNT DUE.
                   RED BILL : "PLEASE PAY YOUR TOTAL BILL"
                   GREEN BILL : "TOTAL BILL"

   version 1.2.0
   revised on : oct 10, 2011
   revised by : lgyap
   remarks    : revised extract_bills procedure
                for billing_batch_no/bill cycle
                additional function get_billing_batch_no that returns billing cycle

   version 1.0.9
   revised on : oct 01, 2011
   revised by : lgyap
   remarks    : -additional function for location code : get_location_code
                -alter procedure add_meter_details for consumption subtractive flag
                -alter procedure extract_bills for the location code
                -new function that returns' line rate for PAR

   version 1.0.8
   revised on : sep 30, 2011
   revised by : lgyap
   remarks    : revise GET_CAS_BILL_NO
                - retrieve directly from ci_bill table

   version 1.0.7
   revised on : Sep 26, 2011
   revised by : jlcomeros
   remarks    : revise GET_DEFAULT_COURIER, GET_AREA_CODE, INSERT_BP_DETAILS and EXTRACT_BILLS

   version 1.0.6
   revised on : aug 22, 2011
   revised by : lgyap
   remarks    : overload procedure : retrieve_last_payment (p_acct_id in varchar2
                                                           ,p_bill_id in varchar2
                                                           ,p_bill_date in date
                                                           ,p_last_pay_date in out date
                                                           ,p_last_pay_amt in out number)
              :accounting date will be used instead of bill date as basis of the retrieval of last payment info

   version 1.0.5
   revised on : aug 3,2011
   revised by : lgyap
   remarks    : revision in procedure insert_bp_details, to include calc lines with zero amounts
                new function created for bill delivery messenger code

   version 1.0.4
   revised on : march 14,2011
   revised by : lgyap
   remarks    : new function created, get cas bill no

   version 1.0.3
   revised on : january 4,2011
   revised by : bmtorrenueva
   remarks    : revised procedure extract bills; getting the old book_no in ci_audit table if the book route is zero or null.
                                                 for tapelist printing purposes (assigning of bills to bills delivery)

   version 1.0.2
   revised on : october 18,2010
   revised by : bmtorrenueva
   remarks    : revised procedure extract bills; getting the applicable bill month
                                                 on bill segment end date (bill month)

   version 1.0.1
   revised on : september 03,2010
   revised by : lgyap
   remarks    : revised procedure extract bills; joining ci_bill_char for bill color
*/ IS

    c_sc_disc_percent      CONSTANT NUMBER := -0.05;
    c_sc_disc_percent_sign CONSTANT VARCHAR2(5) := '5%';
    
    

    PROCEDURE remove_zero_line_amt (
        p_tran_no IN NUMBER
    ) AS
    BEGIN
        DELETE FROM bp_details
        WHERE
            line_code IN ( 'USC', 'UDSC', 'UETR', 'GEN-CHRADJ', 'GEN-CHRADJ_FLT',
                           'SL-CHRADJ', 'SYS-CHRADJ', 'SYS-CHRADJ_FLT', 'TRX-CHRADJ', 'TRX-CHRADJ_FLT',
                           'TRX-CHRADJ_KW' )
            AND line_amount = 0
            AND tran_no = p_tran_no;

    END remove_zero_line_amt;

    FUNCTION get_text_only_tag (
        p_acct_id IN VARCHAR2
    ) RETURN VARCHAR2 AS
        l_txt_only VARCHAR2(1);
    BEGIN
        BEGIN
            l_txt_only := 'N';
            SELECT
                'Y'
            INTO l_txt_only
            FROM
                ci_acct_char
            WHERE
                    char_type_cd = 'PRISMSNO'
                AND acct_id = p_acct_id;

        EXCEPTION
            WHEN no_data_found THEN
                l_txt_only := 'N';
            WHEN too_many_rows THEN
                l_txt_only := 'Y';
        END;

        RETURN l_txt_only;
    END;

    PROCEDURE summarize_gsl (
        p_bill_id IN VARCHAR2
    ) AS
    BEGIN
        FOR l_cur_bp IN (
            SELECT
                a.tran_no
            FROM
                bpx.bp_headers a
            WHERE
                    a.bill_no = p_bill_id
                AND EXISTS (
                    SELECT
                        1
                    FROM
                        bpx.bp_details b
                    WHERE
                            b.tran_no = a.tran_no
                        AND b.line_code IN ( 'CM-GSL1', 'CM-GSL3', 'CM-GSL2' )
                )
        ) LOOP
            DECLARE
                l_line_amount NUMBER;
            BEGIN
                SELECT
                    nvl(SUM(line_amount), 0)
                INTO l_line_amount
                FROM
                    bpx.bp_details
                WHERE
                        tran_no = l_cur_bp.tran_no
                    AND line_code IN ( 'CM-GSL1', 'CM-GSL3', 'CM-GSL2' );

                INSERT INTO bpx.bp_details (
                    tran_no,
                    line_code,
                    line_rate,
                    line_amount
                ) VALUES (
                    l_cur_bp.tran_no,
                    'CM-GSL99',
                    NULL,
                    l_line_amount
                );

                DELETE FROM bpx.bp_details
                WHERE
                        tran_no = l_cur_bp.tran_no
                    AND line_code IN ( 'CM-GSL1', 'CM-GSL3', 'CM-GSL2' );

                COMMIT;
            END;
        END LOOP;
    END summarize_gsl;

    PROCEDURE log_error (
        p_action           IN VARCHAR2,
        p_oracle_error_msg IN VARCHAR2,
        p_custom_error_msg IN VARCHAR2 DEFAULT NULL,
        p_table_name       IN VARCHAR2 DEFAULT NULL,
        p_pk1              IN VARCHAR2 DEFAULT NULL,
        p_pk2              IN VARCHAR2 DEFAULT NULL,
        p_pk3              IN VARCHAR2 DEFAULT NULL
    ) AS
        PRAGMA autonomous_transaction;
    BEGIN
        INSERT INTO error_logs (
            logged_by,
            logged_on,
            module,
            action,
            oracle_error_msg,
            custom_error_msg,
            table_name,
            pk1,
            pk2,
            pk3
        ) VALUES (
            user,
            sysdate,
            'BP_EXTRACT_PKG',
            p_action,
            p_oracle_error_msg,
            p_custom_error_msg,
            p_table_name,
            p_pk1,
            p_pk2,
            p_pk3
        );

        dbms_application_info.set_action('Error Encountered.');
        COMMIT;
    END log_error;
    
    function get_bd_bseg_amt(p_bill_no in varchar2
                             ) return number as
    l_bd_amt   number;
    l_calc_amt number;
    
    begin
      
             select sum(nvl(cbs.cur_amt,0))
             into l_calc_amt
                    from ci_bseg cb,
                         ci_bseg_calc_ln cbsegln,
                         ci_sa csa,
                         ci_sa_type csat,
                         ci_bill_sa cbs
                  where cb.sa_id = csa.sa_id
                  and   cb.bseg_id = cbsegln.bseg_id
                  and   csa.sa_type_cd = csat.sa_type_cd
                  and   cb.sa_id = cbs.sa_id
                  and   cbs.sa_id = csa.sa_id
                  and   cbs.bill_id = cb.bill_id
                  and   csat.bill_seg_type_cd = 'REC-TATB'
                  and   csat.sa_type_cd = 'D-BILL  '
                  and   cb.bseg_stat_flg in ('50','70') --frozen/ok
                  and   csa.sa_status_flg = '20' --active
                  and   cb.bill_id = p_bill_no;
      
      l_bd_amt := l_calc_amt;
      
      return(l_bd_amt);
      
      /*EXCEPTION
            WHEN OTHERS THEN
                l_bd_amt := 0;*/
      EXCEPTION
            WHEN OTHERS THEN
                log_error('GET_BD_BSEG_AMT ' || p_bill_no, sqlerrm, 'Error in retrieving BD bseg amount', NULL, NULL,

                         NULL, NULL);
                         
      --return(l_bd_amt);
    
    end;

    FUNCTION get_lpc (
        p_bill_id IN VARCHAR2,
        p_sa_id   IN VARCHAR2
    ) RETURN NUMBER AS
        l_lpc_amt NUMBER := 0;
    BEGIN
        BEGIN
            SELECT /*+RULE*/
                nvl(SUM(cur_amt), 0) lpc_amount
            INTO l_lpc_amt
            FROM
                ci_ft ft
            WHERE
                    ft.bill_id = p_bill_id
                AND ft.sa_id = p_sa_id
                AND ft.ft_type_flg = 'AD'
                AND parent_id = 'SURCHADJ';

        EXCEPTION
            WHEN OTHERS THEN
                log_error('GET_LPC ' || p_bill_id, sqlerrm, 'Error in retrieving lpc amount', NULL, NULL,
                         NULL, NULL);

                l_lpc_amt := 0;
        END;

        RETURN l_lpc_amt;
    END;

    FUNCTION get_overdue_amt90 (
        p_bill_no IN VARCHAR2
    ) RETURN NUMBER IS
        l_elec_bal NUMBER;
        l_xfer_amt NUMBER;
        l_prev_bal NUMBER;
    BEGIN
        /*
          2020.06.04 - BCC : changed script to get previous balance
            to match how CC gets the previous balance for the Bill
            the Arrears date is not considered
        */
        BEGIN
            SELECT
                prev_balance
            INTO l_elec_bal
            FROM
                (
                    WITH bill AS (
                        SELECT
                            b.acct_id,
                            b.bill_dt,
                            b.bill_id,
                            b.complete_dttm,
                            cre_dttm
                        FROM
                            ci_bill b
                        WHERE
                            b.bill_id = p_bill_no
                    ), prev_trans AS (
                        SELECT
                            nvl(SUM(cur_amt), 0) sum_prev_trans
                        FROM
                            ci_ft      ft,
                            ci_sa      sa,
                            ci_sa_type sat,
                            bill       b
                        WHERE
                                sa.sa_id = ft.sa_id
                            AND sa.acct_id = b.acct_id
                            AND sa.sa_type_cd = sat.sa_type_cd
                            AND sat.debt_cl_cd <> 'DEP'
                                                                                      --and    ars_dt <= b.bill_dt -- commented out by BCC
                            AND ft.bill_id <> b.bill_id
                            AND ft.freeze_dttm < b.complete_dttm -- modified by BCC
                    ), bill_sweep AS (
                        SELECT
                            nvl(SUM(cur_amt), 0) sum_bill_sweep
                        FROM
                            ci_ft      ft,
                            ci_sa      sa,
                            ci_sa_type sat,
                            bill       b
                        WHERE
                                sa.sa_id = ft.sa_id
                            AND sa.acct_id = b.acct_id
                            AND sa.sa_type_cd = sat.sa_type_cd
                            AND sat.debt_cl_cd <> 'DEP'
                            AND ( ft.ft_type_flg IN ( 'PS', 'PX' )
                                  OR ( ft.ft_type_flg = 'BX'
                                       AND ft.parent_id <> ft.bill_id ) )
                            AND ft.bill_id = p_bill_no
                    )
                    SELECT
                        ( sum_prev_trans + sum_bill_sweep ) prev_balance,
                        sum_prev_trans,
                        sum_bill_sweep
                    FROM
                        prev_trans,
                        bill_sweep
                );

            -- commented out by BCC
            /* select sum(abs(cur_amt))/2
               into l_xfer_amt
             from ci_ft ft1
            where bill_id = p_bill_no
              and parent_id = 'XFERPA2'*/

            ---- PA-ECQ
            SELECT
                SUM(cur_amt)
            INTO l_xfer_amt
            FROM
                ci_ft ft,
                ci_sa sa
            WHERE
                    sa.sa_id = ft.sa_id
                AND ft.bill_id = p_bill_no
                AND ft.parent_id = 'XFERPA2'
                AND sa.sa_type_cd IN ( 'PA-ECQ', 'PA-ARB' );

            l_prev_bal := nvl(l_elec_bal, 0) - nvl(l_xfer_amt, 0);
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;

        RETURN ( l_prev_bal );
    END get_overdue_amt90;

    PROCEDURE add_ecq_info (
        p_tran_no      IN NUMBER,
        p_bill_id      IN VARCHAR2,
        p_tot_bill_amt NUMBER
    ) AS

        /*
            v1.3.3 by LGYAP on April 30, 2020
                 Purpose of Change : ECQ related enhancements
                 Remarks           : add_ecq_info
        */

        l_ecq_bal         NUMBER;
        l_outstanding_amt NUMBER;
        l_terms           VARCHAR2(20);
        l_bs_count        NUMBER;
        l_pa_sa_id        VARCHAR2(20);
        l_line            NUMBER;
        l_xfer_amt        NUMBER;
    BEGIN
        BEGIN
            l_line := 10;
            SELECT
                sa.sa_id
            INTO l_pa_sa_id
            FROM
                ci_bseg bseg,
                ci_sa   sa
            WHERE
                    bseg.sa_id = sa.sa_id
                AND sa_type_cd = 'PA-ECQ'
                AND bseg.bill_id = p_bill_id
                AND bseg.bseg_stat_flg IN ( '50', '70' ); -->> v1.3.6

            -- adjusting nCCBADJ:Credit Adjustment
            DECLARE
                l_adj_amt    NUMBER;
                l_xfer_amt   NUMBER;
                l_xfer_count NUMBER;
            BEGIN
                l_line := 12;
                SELECT
                    line_amount
                INTO l_adj_amt
                FROM
                    bp_details
                WHERE
                        tran_no = p_tran_no
                    AND line_code = 'nCCBADJ';

                l_line := 14;
                SELECT
                    nvl(COUNT(*), 0),
                    SUM(cur_amt)
                INTO
                    l_xfer_count,
                    l_xfer_amt
                FROM
                    ci_ft
                WHERE
                        sa_id = l_pa_sa_id
                    AND parent_id IN ( 'XFERPA2' );

                IF l_xfer_count = 1 THEN
                    IF l_adj_amt = ( l_xfer_amt ) * ( -1 ) THEN
                        l_line := 15;
                        DELETE FROM bp_details
                        WHERE
                                tran_no = p_tran_no
                            AND line_code = 'nCCBADJ';

                    ELSIF l_adj_amt <> ( l_xfer_amt * ( -1 ) ) THEN
                        l_line := 16;
                        UPDATE bp_details
                        SET
                            line_amount = line_amount - ( l_xfer_amt ) * ( - 1 )
                        WHERE
                                tran_no = p_tran_no
                            AND line_code = 'nCCBADJ';

                    END IF;

                    --updating previous amount
                    l_line := 17;
                    UPDATE bp_details
                    SET
                        line_amount = line_amount - ( l_xfer_amt )
                    WHERE
                            tran_no = p_tran_no
                        AND line_code = 'OVERDUE';

                END IF;

            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;

            l_line := 20;
            SELECT
                ft2.ecq_bal,
                bs_count,
                terms
            INTO
                l_ecq_bal,
                l_bs_count,
                l_terms
            FROM
                (
                    SELECT
                        ft.*,
                        ft.run_bal - run_cur     ecq_bal,
                        SUM(decode(ft.ft_type_flg, 'BS', 1, 0))
                        OVER(PARTITION BY ft.grp
                             ORDER BY
                                 ft.freeze_dttm
                        )                        AS bs_count,
                        TRIM(sac.adhoc_char_val) terms
                    FROM
                        (
                            SELECT
                                ft_id,
                                sa_id,
                                parent_id,
                                ft_type_flg,
                                cur_amt,
                                tot_amt,
                                freeze_dttm,
                                SUM(cur_amt)
                                OVER(
                                ORDER BY
                                    freeze_dttm
                                ) AS run_cur,
                                SUM(tot_amt)
                                OVER(
                                ORDER BY
                                    freeze_dttm
                                ) AS run_bal,
                                MAX(decode(parent_id, 'SYNC-PA     ', freeze_dttm))
                                OVER(
                                ORDER BY
                                    freeze_dttm
                                ) grp
                            FROM
                                ci_ft
                            WHERE
                                sa_id = l_pa_sa_id
                        )          ft,
                        ci_sa_char sac
                    WHERE
                            ft.sa_id = sac.sa_id
                        AND sac.char_type_cd = 'PATERM'
                ) ft2
            WHERE
                ft2.parent_id = p_bill_id;

            l_outstanding_amt := l_ecq_bal + p_tot_bill_amt;
            l_terms := to_char(l_bs_count)
                       || ' of '
                       || l_terms;
            l_line := 30;
            UPDATE bp_details
            SET
                line_rate = l_terms
            WHERE
                    tran_no = p_tran_no
                AND line_code = 'PA-ECQ';

            l_line := 35;
            INSERT INTO bp_details (
                tran_no,
                line_code,
                line_rate,
                line_amount
            ) VALUES (
                p_tran_no,
                'ECQ_SPACE',
                NULL,
                NULL
            );

            l_line := 40;
            INSERT INTO bp_details (
                tran_no,
                line_code,
                line_rate,
                line_amount
            ) VALUES (
                p_tran_no,
                'ECQ_BAL',
                NULL,
                l_ecq_bal
            );

            l_line := 50;
            INSERT INTO bp_details (
                tran_no,
                line_code,
                line_rate,
                line_amount
            ) VALUES (
                p_tran_no,
                'TOT_W_ECQ',
                NULL,
                l_outstanding_amt
            );

            --deleting lines with zero amounts
            l_line := 60;
            BEGIN
                DELETE FROM bp_details
                WHERE
                        tran_no = p_tran_no
                    AND line_amount = 0
                    AND line_code NOT IN ( 'OVERDUE', 'PREVAMTSPACER', 'CURCHARGES', 'vGENCHGHDR', 'GEN',
                                           'PAR', 'TRX-KWH', 'SYS', 'vGENTRANSTOT', 'vDISTREVHDR',
                                           'DIST', 'SVR', 'MVR', 'MFX', 'vDISTREVTOT',
                                           'vOTHHDR', 'SLF-C', 'R-SLF', 'NPC_ADJKWH', 'vOTHTOT',
                                           'vGOVREVHDR', 'FCT', 'vVATHDR', 'VAT-GEN', 'VAT-TRX',
                                           'VAT-SYS', 'VAT-DIS', 'VAT-OTH', 'vVATTOT', 'vUNIVCHGHDR',
                                           'UC-ME-SPUG', 'UC-ME-RED', 'FITA-KWH2', 'vGOVTOT', 'CURBIL',
                                           'NETSPACER', 'RED_OUTAMT', 'CCBREDNOTICE', 'CCBNOTICE1', 'PA-ECQ',
                                           'ECQ_SPACE', 'ECQ_BAL', 'TOT_W_ECQ', 'GREEN_OUTAMT', 'CCBNOTICE' );

            END;

        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    EXCEPTION
        WHEN OTHERS THEN
            log_error('add_ecq_info SA ID:'
                      || l_pa_sa_id
                      || ' Bill id:'
                      || p_bill_id, sqlerrm, 'Error in populating ecq info @ line: ' || to_char(l_line), NULL, NULL,
                     NULL, NULL);
    END add_ecq_info;

    PROCEDURE adjust_pa_arrears (
        p_tran_no IN NUMBER,
        p_bill_id IN VARCHAR2
    ) AS
        l_pa_sa_id   VARCHAR2(20);
        l_xfer_amt   NUMBER := 0;
        l_xfer_count NUMBER := 0;
        /*l_adj_amt    number;*/
    BEGIN
        BEGIN
            SELECT
                sa.sa_id
            INTO l_pa_sa_id
            FROM
                ci_bseg bseg,
                ci_sa   sa
            WHERE
                    bseg.sa_id = sa.sa_id
                AND sa_type_cd = 'PA-ARB'
                AND bseg.bill_id = p_bill_id
                AND bseg.bseg_stat_flg IN ( '50', '70' ); -->> v1.3.6
        EXCEPTION
            WHEN no_data_found THEN
                RETURN;
        END;

        /*begin
          select line_amount
            into l_adj_amt
            from bp_details
           where tran_no = p_tran_no
             and line_code = 'PA-ARB';
        exception
          when no_data_found then
            l_adj_amt := 0;
        end;*/

        SELECT
            COUNT(*),
            nvl(SUM(cur_amt), 0)
        INTO
            l_xfer_count,
            l_xfer_amt
        FROM
            ci_ft
        WHERE
                sa_id = l_pa_sa_id
            AND parent_id IN ( 'XFERPA2' );

        IF l_xfer_count > 0 THEN
            UPDATE bp_details a
            SET
                line_amount = line_amount + l_xfer_amt
            WHERE
                    tran_no = p_tran_no
                AND line_code = 'PA-ARB';

        END IF;

    END adjust_pa_arrears;

    FUNCTION get_tin (
        p_acct_id IN VARCHAR2
    ) RETURN VARCHAR2 AS
        tin_l VARCHAR2(16);
    BEGIN
        BEGIN
            SELECT
                substr(per_id.per_id_nbr, 1, 18)
            INTO tin_l
            FROM
                ci_per_id   per_id,
                ci_acct_per acct_per
            WHERE
                    per_id.per_id = acct_per.per_id
                AND per_id.id_type_cd = 'TIN     '
                AND acct_per.main_cust_sw = 'Y'
                AND acct_id = p_acct_id;

        EXCEPTION
              WHEN no_data_found THEN
                        NULL;
            WHEN too_many_rows THEN
                NULL;
        END;

        RETURN tin_l;
    END get_tin;

    FUNCTION get_business_style (
        p_sa_id IN VARCHAR2
    ) RETURN VARCHAR2 AS
        l_business_style VARCHAR2(250);
    BEGIN
        BEGIN
            SELECT
                bus_activity_desc
            INTO l_business_style
            FROM
                ci_sa
            WHERE
                sa_id = p_sa_id;

        EXCEPTION
            WHEN OTHERS THEN
                log_error('get_business_style', sqlerrm, 'Error in retrieving business styel', 'CI_SA', p_sa_id,
                         NULL, NULL);
        END;

        RETURN l_business_style;
    END get_business_style;

    PROCEDURE retrieve_business_address (
        p_acct_id  IN VARCHAR2,
        p_address1 IN OUT VARCHAR2,
        p_address2 IN OUT VARCHAR2,
        p_address3 IN OUT VARCHAR2,
        p_address4 IN OUT VARCHAR2,
        p_address5 IN OUT VARCHAR2
    ) AS
    BEGIN
        BEGIN
            SELECT
                p.address1,
                p.address2,
                p.address3,
                p.address4,
                p.city
            INTO
                p_address1,
                p_address2,
                p_address3,
                p_address4,
                p_address5
            FROM
                ci_acct_per ap,
                ci_per      p
            WHERE
                    ap.per_id = p.per_id
                AND ap.acct_id = p_acct_id
                AND ap.acct_rel_type_cd = 'MAINCU  '
                AND ap.main_cust_sw = 'Y';

        EXCEPTION
            WHEN no_data_found THEN
                p_address1 := NULL;
                p_address2 := NULL;
                p_address3 := NULL;
                p_address4 := NULL;
                p_address5 := NULL;
            WHEN OTHERS THEN
                log_error('Retrieving premise address.', sqlerrm, 'p_acct_id', NULL, p_acct_id,
                         NULL, NULL);
        END;
    END retrieve_business_address;

    PROCEDURE retrieve_billing_address (
        p_acct_id  IN VARCHAR2,
        p_address1 IN OUT VARCHAR2,
        p_address2 IN OUT VARCHAR2,
        p_address3 IN OUT VARCHAR2
    ) AS
        l_address VARCHAR2(4000);
    BEGIN
        BEGIN
            SELECT
                p.address1,
                p.address2,
                p.address3
                || ' '
                || p.address4
                || ' '
                || p.city
            INTO
                p_address1,
                p_address2,
                p_address3
            FROM
                ci_acct_per      ap,
                ci_per_addr_ovrd p
            WHERE
                    ap.per_id = p.per_id
                AND ap.acct_id = p_acct_id
                AND ap.acct_rel_type_cd = 'MAINCU  '
                AND ap.main_cust_sw = 'Y';

        EXCEPTION
            WHEN no_data_found THEN
                NULL;
            WHEN OTHERS THEN
                log_error('Retrieving billing address.', sqlerrm, 'p_acct_id', NULL, p_acct_id,
                         NULL, NULL);
        END;
    END retrieve_billing_address;

    PROCEDURE bill_print_sweeper AS
        l_du_set_id NUMBER;
    BEGIN
        l_du_set_id := to_number(to_char(sysdate, 'YYYYMMDD'));
        FOR l_cur IN (
            SELECT
                br.batch_cd,
                br.batch_nbr,
                br.bill_id
            FROM
                ci_bill_char    bchar,
                ci_bill         b,
                ci_bill_routing br
            WHERE
                    bchar.char_type_cd = 'BILLIND '
                AND bchar.bill_id = b.bill_id
                AND b.bill_stat_flg = 'C'
                AND b.complete_dttm >= trunc(sysdate) - 2
                AND b.complete_dttm < trunc(sysdate) + 1
                AND br.bill_id = b.bill_id
                AND br.bill_rte_type_cd IN ( 'POSTAL', 'POSTAL2' )
                AND NOT EXISTS (
                    SELECT
                        NULL
                    FROM
                        bpx.bp_headers h
                    WHERE
                        h.bill_no = b.bill_id
                )
        ) LOOP
            DECLARE
                l_errmsg VARCHAR2(1000);
            BEGIN
                bp_extract_pkg.extract_bills(l_cur.batch_cd, l_cur.batch_nbr, l_du_set_id, 1, NULL,
                                            NULL, l_cur.bill_id);

            EXCEPTION
                WHEN OTHERS THEN
                    l_errmsg := sqlerrm;
                    ROLLBACK;
                    log_error('Extract yesterday''s remaining unextracted bills', l_errmsg, 'Error encountered while extracting the remaining bills',
                    'CI_BILL_ROUTING', l_cur.bill_id,
                             NULL, NULL);

            END;
        END LOOP;

    END bill_print_sweeper;

    PROCEDURE populate_bp_bir_2013 (
        p_tran_no IN NUMBER,
        p_bill_id IN VARCHAR2
    ) AS
        --Version History
        /*--------------------------------------------------------
        v1.3.1 by AOCARCALLAS on March 31, 2017
        Remarks : Correction remove condition (and calc_ln.descr_on_bill <> 'BIR 2306 PPVAT - Transco'):
                  -- for total amount of BIR 2306

        v1.3.0 by LGYAP on March 03, 2017
        Remarks : Revise Computation for the following items:
                  VATable Sales             vGENTRANSTOT + vDISTREVTOT + vOTHTOT
                  VAT Exempt Sales          vGOVTOT - vat_amount
                  VAT Zero Rated Sales        0.00
                  VAT Amount                vat_amount
                  TOTAL SALES               Total of the above items

                  - Please take note that in the RDF :
                       VATable Sales is TOTAL SALES
                       TOTAL SALES is VATable Sales

        */
        -----

        total_sales_l      NUMBER;
        vat1_l             NUMBER;
        net_of_vat_l       NUMBER;
        bir_2306_l         NUMBER;
        bir_2307_l         NUMBER;
        sc_pwd_disc_l      NUMBER;
        amount_due_l       NUMBER;
        vat2_l             NUMBER;
        total_amount_due_l NUMBER;
        vatable_sales_l    NUMBER;
        vat_exempt_sales_l NUMBER;
        vat_0rated_sales_l NUMBER;
        vat_amount_l       NUMBER;
        total_sales2_l     NUMBER;
        err_line_l         NUMBER;
        errmsg_l           VARCHAR2(2000);
    BEGIN
        ---------------------------------------------------------------------------
        -- Below is the layout required by BIR
        ---------------------------------------------------------------------------
        -- total_sales_l      (-> Total Sales(VAT Inclusive)   1,455.28
        -- vat1_l             (-> Less : VAT                      43.95
        -- net_of_vat_l       (-> Amount Net of VAT            1,411.33
        -- bir_2306_l         (-> Less : BIR 2306                 18.36
        -- bir_2307_l         (->        BIR 2307                 11.36     VATable Sales           1,455.28
        -- sc_pwd_disc_l      (->        SC/PWS DISCOUNT           0.00     VAT Exempt Sales            0.00
        -- amount_due_l       (-> Amount Due                   1,381.61     VAT Zero Rated Sales    1,455.28
        -- vat2_l             (-> Add : VAT                       43.95     VAT Amount                 43.95
        -- total_amount_due_l (-> TOTAL AMOUNT DUE             1,425.56     TOTAL SALES             1,411.33
        ---------------------------------------------------------------------------

        -- 1st part
        err_line_l := 10;
        BEGIN
            -- for total sales
            -- Total Sales(VAT Inclusive)
            SELECT
                nvl(bill_amt, 0)
            INTO total_sales_l
            FROM
                bp_headers
            WHERE
                tran_no = p_tran_no;

        END;

        err_line_l := 20;
        BEGIN
            -- for total vat
            -- Less : VAT
            SELECT
                nvl(SUM(line_amount), 0)
            INTO vat1_l
            FROM
                bp_details
            WHERE
                line_code LIKE 'VAT-%'
                AND tran_no = p_tran_no;

        END;

        err_line_l := 30;
        BEGIN
            -- Amount Net of VAT
            net_of_vat_l := total_sales_l - vat1_l;
        END;
        err_line_l := 40;
        BEGIN
            -- for total amount of BIR 2306
            -- Less : BIR 2306
            SELECT
                nvl(abs(SUM(calc_ln.calc_amt)), 0)
            INTO bir_2306_l
            FROM
                ci_bseg         bseg,
                ci_bseg_calc_ln calc_ln
            WHERE
                    bseg.bseg_id = calc_ln.bseg_id
                AND bseg.bill_id = p_bill_id
                AND bseg.bseg_stat_flg IN ( '50', '70' ) -->> v1.3.6
                AND calc_ln.descr_on_bill LIKE 'BIR 2306 PPVAT%';

        END;

        err_line_l := 50;
        BEGIN
            -- for total amount of BIR_2307
            -- BIR 2307
            SELECT
                nvl(abs(SUM(calc_ln.calc_amt)), 0)
            INTO bir_2307_l
            FROM
                ci_bseg         bseg,
                ci_bseg_calc_ln calc_ln
            WHERE
                    bseg.bseg_id = calc_ln.bseg_id
                AND bseg.bill_id = p_bill_id
                AND bseg.bseg_stat_flg IN ( '50', '70' ) -->> v1.3.6
                AND calc_ln.descr_on_bill LIKE 'BIR 2307 PPWTAX%';

        END;

        err_line_l := 60;
        BEGIN
            -- for total amount of senior citizen discount or pwd discount
            -- SC/PWS DISCOUNT
            SELECT
                nvl(abs(SUM(calc_ln.calc_amt)), 0)
            INTO sc_pwd_disc_l
            FROM
                ci_bseg         bseg,
                ci_bseg_calc_ln calc_ln
            WHERE
                    bseg.bseg_id = calc_ln.bseg_id
                AND bseg.bill_id = p_bill_id
                AND bseg.bseg_stat_flg IN ( '50', '70' ) -->> v1.3.6
                AND calc_ln.char_type_cd = 'CM-SCCAT';

        END;

        err_line_l := 70;
        BEGIN
            -- for net amount
            -- Amount Due
            amount_due_l := net_of_vat_l - ( bir_2306_l + bir_2307_l + sc_pwd_disc_l );
        END;
        err_line_l := 80;
        BEGIN
            -- for vat
            --Add : VAT

            vat2_l := vat1_l;
        END;
        err_line_l := 90;
        BEGIN
            -- TOTAL AMOUNT DUE
            total_amount_due_l := amount_due_l + vat1_l;
        END;

        --2nd part
        err_line_l := 100;
        BEGIN
            -- for vatables sales
            IF ( vat1_l = 0 ) THEN
                vatable_sales_l := 0;
            ELSE
                vatable_sales_l := total_sales_l;
            END IF;
        END;

        err_line_l := 110;
        BEGIN
            -- for vat exempt sales
            vat_exempt_sales_l := 0;
        END;
        err_line_l := 120;
        BEGIN
            -- for vat zero rated sales
            IF ( vat1_l = 0 ) THEN
                vat_0rated_sales_l := total_sales_l;
            ELSE
                vat_0rated_sales_l := 0;
            END IF;
        END;

        err_line_l := 130;
        BEGIN
            -- for vat amount
            vat_amount_l := vat1_l;
        END;
        err_line_l := 140;
        BEGIN
            -- for total sales
            total_sales2_l := total_sales_l - vat1_l;
        END;

        --v1.3.0 by LGYAP on March 03, 2017
        DECLARE
            l_gen_total        NUMBER;
            l_dst_total        NUMBER;
            l_oth_total        NUMBER;
            l_gov_total        NUMBER;
            l_lft_total        NUMBER; --01/11/2024
            l_x_vat_amt        NUMBER;
            l_x_vatable_amt    NUMBER;
            l_x_vat_exempt_amt NUMBER;
            l_x_zero_rated_amt NUMBER;
            l_x_total_amt      NUMBER;
        BEGIN
            err_line_l := 150;
            SELECT
                SUM(decode(line_code, 'vGENTRANSTOT', line_amount, 0)) gen,
                SUM(decode(line_code, 'vDISTREVTOT', line_amount, 0))  dst,
                SUM(decode(line_code, 'vOTHTOT', line_amount, 0))      oth,
                SUM(decode(line_code, 'vGOVTOT', line_amount, 0))      gov,
                SUM(decode(line_code, 'FCT', line_amount, 0))          lft
            INTO
                l_gen_total,
                l_dst_total,
                l_oth_total,
                l_gov_total,
                l_lft_total
            FROM
                bp_details
            WHERE
                    tran_no = p_tran_no
                AND line_code IN ( 'vGENTRANSTOT', 'vDISTREVTOT', 'vOTHTOT', 'vGOVTOT', 'FCT' );

            err_line_l := 160;
            l_x_vat_amt := vat1_l;
            l_x_vatable_amt := l_gen_total + l_dst_total + l_oth_total + l_lft_total;
            l_x_zero_rated_amt := 0;
            l_x_vat_exempt_amt := l_gov_total - l_x_vat_amt - l_lft_total;
            l_x_total_amt := total_sales_l;
            IF ( l_x_vat_amt = 0 ) THEN
                l_x_zero_rated_amt := l_x_vatable_amt;
                l_x_vatable_amt := 0;
            END IF;

            err_line_l := 160;
            vatable_sales_l := l_x_total_amt;
            vat_exempt_sales_l := l_x_vat_exempt_amt;
            vat_0rated_sales_l := l_x_zero_rated_amt;
            vat_amount_l := l_x_vat_amt;
            total_sales2_l := l_x_vatable_amt;
        END;

        BEGIN
            err_line_l := 180;
            INSERT INTO bp_bir_2013 (
                tran_no,
                total_sales,
                vat1,
                amount_net_of_vat,
                bir_2306,
                bir_2307,
                sc_pwd_disc,
                amount_due,
                vat2,
                total_amount_due,
                vatable_sales,
                vat_exempt_sales,
                vat_zero_rated_sales,
                vat_amount,
                total_sales2
            ) VALUES (
                p_tran_no,
                total_sales_l,
                vat1_l,
                net_of_vat_l,
                bir_2306_l,
                bir_2307_l,
                sc_pwd_disc_l,
                amount_due_l,
                vat2_l,
                total_amount_due_l,
                vatable_sales_l,
                vat_exempt_sales_l,
                vat_0rated_sales_l,
                vat_amount_l,
                total_sales2_l
            );

        END;

    EXCEPTION
        WHEN OTHERS THEN
            log_error('Bill ID :'
                      || p_bill_id
                      || '-Tran No'
                      || p_tran_no, sqlerrm, 'Error while inserting BP BIR 2013 @ line ' || err_line_l, NULL, NULL,
                     NULL, NULL);
    END populate_bp_bir_2013;

    FUNCTION get_cas_bill_no (
        p_bill_id IN VARCHAR2
    ) RETURN VARCHAR2 AS
        -- function that returns CAS bill no
        l_bill_no ci_bill_char.adhoc_char_val%TYPE;
    BEGIN
        /*begin
           select adhoc_char_val
           into   l_bill_no
           from   ci_bill_char
           where  bill_id = p_bill_id
           and    char_type_cd = 'CMSRVINV';
        exception
           when no_data_found
           then
              null;
        end;*/

        --new version for october 2011 billing
        BEGIN
            SELECT
                alt_bill_id
            INTO l_bill_no
            FROM
                ci_bill
            WHERE
                bill_id = p_bill_id;

        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;

        RETURN l_bill_no;
    END get_cas_bill_no;

    FUNCTION get_extract_bill_count (
        p_batch_cd  IN VARCHAR2,
        p_batch_nbr IN NUMBER
    ) RETURN NUMBER IS
        l_extract_bill_count NUMBER;
    BEGIN
        BEGIN
            SELECT
                COUNT(*)
            INTO l_extract_bill_count
            FROM
                ci_bill_routing br
            WHERE
                br.bill_rte_type_cd IN ( 'POSTAL', 'POSTAL2' )
                AND br.seqno = 1 -- just get the first entry in the bill routing
                AND br.batch_cd = rpad(p_batch_cd, 8)
                AND br.batch_nbr = p_batch_nbr
                AND NOT EXISTS (
                    SELECT
                        NULL
                    FROM
                        bp_headers
                    WHERE
                        bill_no = br.bill_id
                );

        EXCEPTION
            WHEN OTHERS THEN
                log_error('Counting bills for Extraction', sqlerrm, NULL, NULL, p_batch_cd,
                         p_batch_nbr, NULL);
                raise_application_error(-20010, sqlerrm);
        END;

        RETURN ( l_extract_bill_count );
    END;

    FUNCTION generate_du_set_id RETURN NUMBER IS
        l_du_set_id NUMBER;
    BEGIN
        BEGIN
            SELECT
                bph_du_set_ids.NEXTVAL
            INTO l_du_set_id
            FROM
                dual;

        EXCEPTION
            WHEN OTHERS THEN
                log_error('Generating du_set_id.', sqlerrm, NULL, 'bph_du_set_ids', NULL,
                         NULL, NULL);
                raise_application_error(-20020, 'Generating du_set_id: ' || sqlerrm);
        END;

        RETURN ( l_du_set_id );
    END;

    FUNCTION get_crc (
        p_acct_id IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_crc ci_acct_char.adhoc_char_val%TYPE;
    BEGIN
        BEGIN
            SELECT
                substr(adhoc_char_val, 1, 10)
            INTO l_crc
            FROM
                ci_acct_char ac
            WHERE
                    ac.acct_id = p_acct_id
                AND ac.char_type_cd = 'CRCCODE';

        EXCEPTION
            WHEN OTHERS THEN
                RETURN NULL;
                --         WHEN NO_DATA_FOUND
            --         THEN
            --            l_crc := 'NO-CRC';
            --         WHEN TOO_MANY_ROWS
            --         THEN
            --            l_crc := 'MULTI-CRC';
            --         WHEN OTHERS
            --         THEN
            --            log_error ('Getting CRC.',
            --                       SQLERRM,
            --                       'Acct_id',
            --                       NULL,
            --                       p_acct_id,
            --                       NULL,
            --                       NULL);
            --            raise_application_error (-20030, p_acct_id || ' ' || SQLERRM);
        END;

        RETURN ( l_crc );
    END;

    FUNCTION get_bdseq (
        p_acct_id IN VARCHAR2
    ) RETURN VARCHAR2
    -- this is the new function for getting the bill delivery sequence
        -- used when the bdseq is added as a characteristic for the account
     IS
        l_bdseq ci_acct_char.adhoc_char_val%TYPE;
    BEGIN
        BEGIN
            SELECT
                adhoc_char_val
            INTO l_bdseq
            FROM
                (
                    SELECT
                        adhoc_char_val
                    FROM
                        ci_acct_char ac
                    WHERE
                            ac.acct_id = p_acct_id
                        AND ac.char_type_cd = 'CM_BDSEQ'
                    ORDER BY
                        effdt DESC
                )
            WHERE
                ROWNUM = 1;

        EXCEPTION
            WHEN no_data_found THEN
                l_bdseq := NULL;
            WHEN OTHERS THEN
                log_error('Getting Bill Delivery Sequence.', sqlerrm, 'Acct_id', NULL, p_acct_id,
                         NULL, NULL);
        END;

        RETURN ( l_bdseq );
    END;

    FUNCTION get_bdmsgr (
        p_acct_id IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_bdmsgr ci_acct_char.adhoc_char_val%TYPE;
    BEGIN
        /*
        begin

            select msgr_code
            into   l_bdmsgr
            from   (select adhoc_char_val msgr_code
                    from   ci_acct_char ac
                    where  ac.acct_id = p_acct_id
                    and    ac.char_type_cd = 'CM_BDMSR'
                    order by effdt desc)
            where  rownum = 1;
        exception
            when no_data_found
            then
                l_bdmsgr := null;
            when others
            then
                log_error ('Getting Bill Delivery Messenger Code.', sqlerrm, 'Acct_id', null, p_acct_id, null, null);
        end;
        */
        SELECT
            MAX(nvl(TRIM(char_val), adhoc_char_val)) KEEP(DENSE_RANK FIRST ORDER BY effdt DESC) msgr_code
        INTO l_bdmsgr
        FROM
            ci_acct_char ac
        WHERE
                ac.acct_id = p_acct_id
            AND ac.char_type_cd = 'CM_BDMSR';

        RETURN ( l_bdmsgr );
    END get_bdmsgr;

    PROCEDURE retrieve_rate_schedule (
        p_bill_id  IN VARCHAR2,
        p_sa_id    IN VARCHAR2,
        p_rs_cd    IN OUT VARCHAR2,
        p_rs_descr IN OUT VARCHAR2
    ) IS
    BEGIN
        SELECT
            MAX(TRIM(bsc.rs_cd)),
            MAX(TRIM(rl.descr))
        INTO
            p_rs_cd,
            p_rs_descr
        FROM
            ci_bseg      bs,
            ci_bseg_calc bsc,
            ci_rs_l      rl
        WHERE
                bs.bseg_id = bsc.bseg_id
            AND bsc.rs_cd = rl.rs_cd
            AND rl.language_cd = 'ENG'
            AND bs.bseg_stat_flg IN ( '50', '70' )
            AND bs.bill_id = p_bill_id
            AND bs.sa_id = p_sa_id;

    EXCEPTION
        WHEN no_data_found THEN
            p_rs_cd := NULL;
            p_rs_descr := NULL;
        WHEN OTHERS THEN
            log_error('Retrieving rate schedule.', sqlerrm, 'bill_id/sa_id', NULL, p_bill_id,
                     p_sa_id, NULL);
    END;

    /*   function get_default_courier (p_rs_cd in varchar2, p_bill_cycle in varchar2) return varchar2
    is
       l_courier_code bp_courier_codes.courier_code%type;
    begin
       if to_number(substr(p_rs_cd, -2)) <= 33
       then
          l_courier_code := '33';
       elsif to_number(substr(p_rs_cd, -2)) > 33  and
             to_number(substr(p_rs_cd, -2)) <= 49
       then
          l_courier_code := '34';
       elsif to_number(substr(p_rs_cd, -2)) > 49
       then
          l_courier_code := 'P';
       elsif trim(p_bill_cycle) is null
       then
          l_courier_code := 'ADHOC';
       end if;
       return(l_courier_code);
    end;*/

    /*--============================================================================
        v1.0.7
          - use infix to determine courier
    */
    --============================================================================
    FUNCTION get_default_courier (
        p_rs_cd      IN VARCHAR2,
        p_bill_cycle IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_courier_code bp_courier_codes.courier_code%TYPE;
    BEGIN
        IF TRIM(p_bill_cycle) IS NOT NULL THEN
            IF substr(trim(p_rs_cd), 4, 1) = 'P' THEN
                l_courier_code := 'P';
            ELSIF substr(trim(p_rs_cd), 4, 1) = 'C' THEN
                l_courier_code := '34';
            ELSE
                l_courier_code := '33';
            END IF;
        ELSIF TRIM(p_bill_cycle) IS NULL THEN
            l_courier_code := 'ADHOC';
        END IF;

        RETURN ( l_courier_code );
    END;

    PROCEDURE retrieve_last_payment (
        p_acct_id       IN VARCHAR2,
        p_bill_date     IN DATE,
        p_last_pay_date IN OUT DATE,
        p_last_pay_amt  IN OUT NUMBER
    ) IS
    BEGIN
        BEGIN
            SELECT
                a.pay_dt,
                a.pay_amt
            INTO
                p_last_pay_date,
                p_last_pay_amt
            FROM
                (
                    SELECT
                        event.pay_dt,
                        pay.pay_amt
                    FROM
                        ci_pay_event event,
                        ci_pay       pay
                    WHERE
                            event.pay_event_id = pay.pay_event_id
                        AND pay.acct_id = p_acct_id
                        AND pay.pay_status_flg = '50'
                        AND event.pay_dt <= p_bill_date
                    ORDER BY
                        event.pay_dt DESC
                ) a
            WHERE
                ROWNUM = 1;

        EXCEPTION
            WHEN no_data_found THEN
                p_last_pay_date := NULL;
                p_last_pay_amt := NULL;
            WHEN OTHERS THEN
                log_error('Retrieving last payment date/amount.', sqlerrm, 'acct_id/bill_dt', NULL, p_acct_id,
                         to_char(p_bill_date, 'yyyy/mm/dd'), NULL);
        END;
    END;

    PROCEDURE retrieve_last_payment (
        p_acct_id       IN VARCHAR2,
        p_bill_id       IN VARCHAR2,
        p_bill_date     IN DATE,
        p_last_pay_date IN OUT DATE,
        p_last_pay_amt  IN OUT NUMBER
    ) IS
    BEGIN
        BEGIN
            SELECT
                a.pay_dt,
                a.pay_amt
            INTO
                p_last_pay_date,
                p_last_pay_amt
            FROM
                (
                    SELECT
                        event.pay_dt,
                        pay.pay_amt
                    FROM
                        ci_pay_event event,
                        ci_pay       pay
                    WHERE
                            event.pay_event_id = pay.pay_event_id
                        AND pay.acct_id = p_acct_id
                        AND pay.pay_status_flg = '50'
                        AND event.pay_dt <= (
                            SELECT
                                MAX(trunc(freeze_dttm))
                            FROM
                                ci_ft
                            WHERE
                                    parent_id = p_bill_id
                                AND ft_type_flg = 'BS'
                        )
                    ORDER BY
                        event.pay_dt DESC
                ) a
            WHERE
                ROWNUM = 1;

        EXCEPTION
            WHEN no_data_found THEN
                p_last_pay_date := NULL;
                p_last_pay_amt := NULL;
            WHEN OTHERS THEN
                log_error('Retrieving last payment date/amount.', sqlerrm, 'acct_id/bill_dt', NULL, p_acct_id,
                         to_char(p_bill_date, 'yyyy/mm/dd'), NULL);
        END;
    END;

    PROCEDURE retrieve_premise_address (
        p_prem_id  IN VARCHAR2,
        p_address1 IN OUT VARCHAR2,
        p_address2 IN OUT VARCHAR2,
        p_address3 IN OUT VARCHAR2
    ) IS
    BEGIN
        BEGIN
            SELECT
                address1,
                address2,
                address3
            INTO
                p_address1,
                p_address2,
                p_address3
            FROM
                ci_prem p
            WHERE
                p.prem_id = p_prem_id;

        EXCEPTION
            WHEN no_data_found THEN
                p_address1 := NULL;
                p_address2 := NULL;
                p_address3 := NULL;
            WHEN OTHERS THEN
                log_error('Retrieving premise address.', sqlerrm, 'prem_id', NULL, p_prem_id,
                         NULL, NULL);
        END;
    END;

    /*--============================================================================
        v1.0.7
          - to be identified
    */
    --============================================================================
    FUNCTION get_area_code (
        p_city IN VARCHAR2
    ) RETURN NUMBER AS
        l_ret  NUMBER;
        l_code VARCHAR2(30);
    BEGIN
        l_ret := 10;

        /*
        l_code := ltrim(rtrim(lower(p_city)));
        if l_code like 'cebu%'
        then
           l_ret := 10;
        elsif l_code like 'mandaue%'
        then
           l_ret := 21;
        elsif l_code like 'consolacion%'
        then
           l_ret := 22;
        elsif l_code like 'lilo-an%'
        then
           l_ret := 23;
        elsif l_code like 'talisay%'
        then
           l_ret := 31;
        elsif l_code like 'minglanilla%'
        then
           l_ret := 32;
        elsif l_code like 'naga%'
        then
           l_ret := 33;
        elsif l_code like 'san fernando%'
        then
           l_ret := 34;
        end if;
        */

        RETURN l_ret;
    END get_area_code;

    FUNCTION get_book_no (
        p_sa_id IN VARCHAR2
    ) RETURN NUMBER IS
        l_book_no NUMBER;
    BEGIN
        SELECT
            MAX(to_number(mr_rte_cd))
        INTO l_book_no
        FROM
            ci_sp    sp,
            ci_sa_sp sap
        WHERE
                sp.sp_id = sap.sp_id
            AND usage_flg = '+'
            AND sap.sa_id = p_sa_id;

        RETURN l_book_no;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_sp_id   VARCHAR2(10);
                l_book_no NUMBER;
            BEGIN
                -- getting the service point id
                SELECT
                    sp.sp_id
                INTO l_sp_id
                FROM
                    ci_sp    sp,
                    ci_sa_sp sap
                WHERE
                        sp.sp_id = sap.sp_id
                    AND sap.usage_flg = '+'
                    AND sap.sa_id = p_sa_id;

                -- getting the old book no in audit table
                SELECT
                    val_before
                INTO l_book_no
                FROM
                    ci_audit
                WHERE
                        audit_tbl_name = 'CI_SP'
                    AND audit_fld_name = 'MR_RTE_CD'
                    AND cre_dttm = (
                        SELECT
                            MAX(cre_dttm)
                        FROM
                            ci_audit
                        WHERE
                                audit_tbl_name = 'CI_SP'
                            AND audit_fld_name = 'MR_RTE_CD'
                            AND pk_value1 = l_sp_id
                    ) -- getting the last updated route no
                    AND pk_value1 = l_sp_id;

                IF l_book_no IS NULL THEN
                    RETURN 0;
                ELSE
                    RETURN to_number(l_book_no);
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    RETURN 0;
            END;
    END;

    --   function get_delivery_sequence (p_acct_id in varchar2) return number
    --   is
    --      l_delivery_sequence number;
    --   begin
    --      -- gets the delivery sequence from the materialized view
    --      -- however as new accts are being built up on ccnb
    --      -- delivery sequence of the new accts will not be reflected on the mview
    --      -- suggest to put the delivery sequence as a characteristic of the acct or person
    --      begin
    --         select delivery_sequence
    --         into   l_delivery_sequence
    --         from   billdel_sequences
    --         where  acct_id = p_acct_id;
    --      exception
    --         when no_data_found
    --         then
    --            l_delivery_sequence := null;
    --         when others
    --         then
    --            dbms_application_info.set_action('Error Encountered.');
    --            raise_application_error(-20004, sqlerrm);
    --      end;
    --      return(l_delivery_sequence);
    --   end;

    FUNCTION get_bill_sq (
        p_bill_id IN VARCHAR2,
        p_sa_id   IN VARCHAR2,
        p_sqi_cd  IN VARCHAR2,
        p_uom_cd  IN VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER IS
        l_bill_sq NUMBER;
    BEGIN
        BEGIN
            SELECT
                MAX(bill_sq)
            INTO l_bill_sq
            FROM
                ci_bseg    bs,
                ci_bseg_sq bsq
            WHERE
                    bs.bseg_id = bsq.bseg_id
                AND bs.bseg_stat_flg IN ( '50', '70' )
                AND bs.bill_id = p_bill_id
                AND bs.sa_id = p_sa_id
                AND sqi_cd = rpad(p_sqi_cd, 8)
                AND nvl(TRIM(uom_cd), '00') = nvl(p_uom_cd, nvl(TRIM(uom_cd), '00'));

        EXCEPTION
            WHEN no_data_found THEN
                l_bill_sq := NULL;
            WHEN OTHERS THEN
                l_bill_sq := 0;
        END;

        RETURN ( l_bill_sq );
    END;

    FUNCTION get_current_bill_amt (
        p_bill_id IN VARCHAR2,
        p_sa_id   IN VARCHAR2
    ) RETURN NUMBER IS
        l_current_bill_amt NUMBER;
    BEGIN
        BEGIN
            SELECT
                bc.calc_amt
            INTO l_current_bill_amt
            FROM
                ci_bseg      bs,
                ci_bseg_calc bc
            WHERE
                    bs.bseg_id = bc.bseg_id
                AND bc.header_seq = 1
                AND bs.bseg_stat_flg IN ( '50', '70' )
                AND bs.bill_id = p_bill_id
                AND bs.sa_id = p_sa_id;

        EXCEPTION
            WHEN OTHERS THEN
                log_error('Getting current billed amount.', sqlerrm, NULL, NULL, p_bill_id,
                         p_sa_id, NULL);
                l_current_bill_amt := 0;
        END;

        -- add late payment charge/surcharge
        l_current_bill_amt := l_current_bill_amt + nvl(get_bill_sq(p_bill_id, p_sa_id, 'ADJLPC'), 0);

        RETURN ( l_current_bill_amt );
    END;

    FUNCTION get_net_bill_amt (
        p_bill_id IN VARCHAR2
    ) RETURN NUMBER IS
        l_net_bill_amt NUMBER;
    BEGIN
        BEGIN
            SELECT
                SUM(cur_amt)
            INTO l_net_bill_amt
            FROM
                ci_bill_sa bsa
            WHERE
                bsa.bill_id = p_bill_id;

        EXCEPTION
            WHEN OTHERS THEN
                log_error('Getting net billed amount.', sqlerrm, NULL, NULL, p_bill_id,
                         NULL, NULL);
        END;

        RETURN ( l_net_bill_amt );
    END;

    FUNCTION get_net_bill_amt2 (
        p_bill_id IN VARCHAR2
    ) RETURN NUMBER IS
    /*
    revision history 
             v1.4.4 by gperater on February 28, 2024
                    purpose of change : enabled to condition or      trim (sa.sa_type_cd) = 'D-BILL' to cater the amounts of BD SA to be added
                                        to the Total Amount Due on bill display
    
    */
        l_net_bill_amt NUMBER;
    BEGIN
        BEGIN
            SELECT
                SUM(cur_amt)
            INTO l_net_bill_amt
            FROM
                ci_bill_sa bsa,
                ci_sa      sa,
                ci_sa_type sat
            WHERE
                    bsa.sa_id = sa.sa_id
                AND sa.sa_type_cd = sat.sa_type_cd
                AND ( TRIM(sat.debt_cl_cd) <> 'DEP'
                or      trim (sa.sa_type_cd) = 'D-BILL' --02/28/2024
                  --or      trim (sa.sa_type_cd) = 'D-BILL'
                 )
                AND bsa.bill_id = p_bill_id;

        EXCEPTION
            WHEN OTHERS THEN
                log_error('Getting net billed amount.', sqlerrm, NULL, NULL, p_bill_id,
                         NULL, NULL);
        END;

        RETURN ( l_net_bill_amt );
    END;

    FUNCTION get_net_bill_amt3 (
        p_bill_id IN VARCHAR2
    ) RETURN NUMBER IS
        l_net_bill_amt NUMBER;
    BEGIN
        BEGIN
            SELECT
                SUM(cur_amt)
            INTO l_net_bill_amt
            FROM
                ci_bill_sa bsa,
                ci_sa      sa,
                ci_sa_type sat
            WHERE
                    bsa.sa_id = sa.sa_id
                AND sa.sa_type_cd = sat.sa_type_cd
                AND TRIM(sat.debt_cl_cd) <> 'DEP'
                AND bsa.bill_id = p_bill_id;

        EXCEPTION
            WHEN OTHERS THEN
                log_error('Getting net billed amount3.', sqlerrm, NULL, NULL, p_bill_id,
                         NULL, NULL);
        END;

        RETURN ( l_net_bill_amt );
    END;

    FUNCTION get_overdue_amt (
        p_bill_id          IN VARCHAR2,
        p_sa_id            IN VARCHAR2,
        p_current_bill_amt IN NUMBER
    ) RETURN NUMBER IS
        l_overdue_amt NUMBER;
    BEGIN
        BEGIN
            SELECT
                cur_amt - p_current_bill_amt
            INTO l_overdue_amt
            FROM
                ci_bill_sa
            WHERE
                    bill_id = p_bill_id
                AND sa_id = p_sa_id;

        EXCEPTION
            WHEN OTHERS THEN
                l_overdue_amt := 0;
        END;

        IF l_overdue_amt < 0 THEN
            l_overdue_amt := 0;
        END IF;
        RETURN ( l_overdue_amt );
    END;

    FUNCTION get_overdue_amt2 (
        p_bill_id IN VARCHAR2
    ) RETURN NUMBER IS
        l_overdue_amt      NUMBER;
        l_current_bill_amt NUMBER;
        l_net_bill_amt     NUMBER;
        l_db_int           NUMBER;
    BEGIN
        l_net_bill_amt := get_net_bill_amt3(p_bill_id);
        SELECT
            SUM(cur_amt)
        INTO l_db_int
        FROM
            ci_ft
        WHERE
                bill_id = p_bill_id
            AND TRIM(parent_id) IN ( 'ANINT2AR', 'ANNBD2AR' );

        -- get current bill amount for all bill segments under the bill
        BEGIN
            SELECT
                SUM(cur_amt)
            INTO l_current_bill_amt
            FROM
                ci_ft      ft,
                ci_sa      sa,
                ci_sa_type sat
            WHERE
                    sa.sa_id = ft.sa_id
                AND sat.sa_type_cd = sa.sa_type_cd
                AND TRIM(sat.debt_cl_cd) <> 'DEP'
                AND bill_id = p_bill_id
                AND ft_type_flg NOT IN ( 'PS', 'PX' );

        EXCEPTION
            WHEN OTHERS THEN
                l_overdue_amt := 0;
        END;

        IF l_current_bill_amt < 0 THEN
            l_overdue_amt := 0;
            IF l_db_int < 0 THEN
                l_overdue_amt := abs(l_current_bill_amt) - abs(l_net_bill_amt);
            END IF;

        ELSE
            l_overdue_amt := l_net_bill_amt - l_current_bill_amt;
        END IF;

        RETURN ( l_overdue_amt );
    END;

    FUNCTION get_overdue_bill_count (
        p_sa_id       IN VARCHAR2,
        p_bill_date   IN DATE,
        p_overdue_amt IN NUMBER
    ) RETURN NUMBER IS

        l_overdue_bill_count NUMBER := 1;
        l_bill_id            VARCHAR2(12) := '0';
        l_overdue_amt        NUMBER := p_overdue_amt;
    BEGIN
        FOR r IN (
            SELECT
                *
            FROM
                (
                    SELECT
                        ft_type_flg,
                        cur_amt,
                        ars_dt,
                        cre_dttm,
                        bill_id,
                        SUM(cur_amt)
                        OVER(PARTITION BY sa_id
                             ORDER BY
                                 ars_dt, cre_dttm
                        ) bal
                    FROM
                        ci_ft
                    WHERE
                            sa_id = p_sa_id
                        AND cur_amt <> 0
                        AND ars_dt < p_bill_date
                    ORDER BY
                        ars_dt,
                        cre_dttm
                )
            ORDER BY
                ars_dt DESC,
                cre_dttm DESC
        ) LOOP
            IF
                r.ft_type_flg = 'BS'
                AND p_overdue_amt <> r.bal
            THEN
                l_overdue_bill_count := l_overdue_bill_count + 1;
            END IF;

            IF p_overdue_amt = r.bal THEN
                EXIT;
            END IF;
        END LOOP;

        RETURN ( l_overdue_bill_count );
    END;

    FUNCTION get_overdue_bill_cnt (
        p_sa_id       IN VARCHAR2,
        p_bill_date   IN DATE,
        p_overdue_amt IN NUMBER
    ) RETURN NUMBER AS
        -- just select up to 10 bill segments
        -- assumption is customer would have been disconnected after more
        -- than 10 overdue bills
        CURSOR ft_cur IS
        SELECT
            *
        FROM
            (
                SELECT
                    ars_dt,
                    SUM(ft.cur_amt) cur_amt
                FROM
                    ci_ft ft
                WHERE
                        sa_id = p_sa_id
                    AND ars_dt < p_bill_date
                    AND ft_type_flg IN ( 'BS', 'BX' )
                GROUP BY
                    ars_dt
                ORDER BY
                    ars_dt DESC
            )
        WHERE
            ROWNUM <= 10;

        TYPE ft_tab_type IS
            TABLE OF ft_cur%rowtype INDEX BY BINARY_INTEGER;
        l_ft   ft_tab_type;
        l_row  PLS_INTEGER;
        l_ctr  NUMBER(10);
        l_prev NUMBER(14, 2);
    BEGIN
        l_ctr := 0;
        l_prev := p_overdue_amt;
        OPEN ft_cur;
        LOOP
            FETCH ft_cur
            BULK COLLECT INTO l_ft;
            l_row := l_ft.first;
            WHILE ( l_row IS NOT NULL ) LOOP
                l_ctr := l_ctr + 1;
                l_prev := l_prev - l_ft(l_row).cur_amt;
                IF ( l_prev <= 0 ) THEN
                    EXIT;
                END IF;
                l_row := l_ft.next(l_row);
            END LOOP;

            IF ( l_prev <= 0 ) THEN
                EXIT;
            END IF;
            EXIT WHEN ft_cur%notfound;
        END LOOP;

        CLOSE ft_cur;
        IF l_ctr > 1 THEN
            l_ctr := l_ctr - 1;
        END IF;
        RETURN ( l_ctr );
    END;

    FUNCTION get_bill_message (
        p_bill_id IN VARCHAR2
    ) RETURN VARCHAR2 IS

        l_bill_message ci_bill_msgs.bill_msg_cd%TYPE;
        CURSOR bill_msg_cur IS
        --           SELECT   bms.bill_msg_cd
        --             FROM   ci_bill_msgs bms, ci_bill_msg bm
        --            WHERE   bms.bill_msg_cd = bm.bill_msg_cd
        --                    AND bms.bill_id = p_bill_id
        --         ORDER BY   bm.msg_priority_flg DESC, bms.bill_msg_cd;
        SELECT
            nvl(bmsgs.bill_msg_cd, bseg_msg.bill_msg_cd)
        FROM
            ci_bseg      bseg,
            ci_bseg_msg  bseg_msg,
            ci_bill_msgs bmsgs,
            ci_bill_msg  bmsg
        WHERE
                bseg.bill_id = p_bill_id
            AND bseg.bseg_stat_flg IN ( '50', '70' ) -->> v1.3.6
            AND bseg.bseg_id = bseg_msg.bseg_id (+)
            AND bseg.bill_id = bmsgs.bill_id (+)
            AND bmsgs.bill_msg_cd = bmsg.bill_msg_cd (+)
            AND EXISTS (
                SELECT
                    1
                FROM
                    ci_sa      sa,
                    ci_sa_type sa_type
                WHERE
                        bseg.sa_id = sa.sa_id
                    AND sa.sa_type_cd = sa_type.sa_type_cd
                    AND sa_type.svc_type_cd = 'EL'
            )
        ORDER BY
            bmsg.msg_priority_flg DESC,
            bmsgs.bill_msg_cd;

    BEGIN
        OPEN bill_msg_cur;
        FETCH bill_msg_cur INTO l_bill_message;
        CLOSE bill_msg_cur;
        RETURN ( l_bill_message );
    END;

    FUNCTION get_pole_no (
        p_sp_id IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_pole_no VARCHAR2(20);
    BEGIN
        BEGIN
            SELECT
                MAX(geo_val)
            INTO l_pole_no
            FROM
                ci_sp_geo spg
            WHERE
                    spg.sp_id = p_sp_id
                AND spg.geo_type_cd LIKE 'POLENO%';

        EXCEPTION
            WHEN OTHERS THEN
                l_pole_no := NULL;
        END;

        RETURN l_pole_no;
    END;

    PROCEDURE old_insert_meter_details (
        p_tran_no IN NUMBER,
        p_bill_id IN VARCHAR2,
        p_sa_id   IN VARCHAR2,
        p_bill_dt IN DATE
    ) IS

        l_md            bp_meter_details%rowtype;
        l_rownum        NUMBER := 0;
        l_curr_badge_no bp_meter_details.badge_no%TYPE;
        l_unmetered_sa  BOOLEAN := true;
    BEGIN
        l_md.meter_count := 0;

        -- loop through all the data in the ci_bseg_read
        FOR r IN (
            SELECT
                m.badge_nbr,
                m.serial_nbr,
                DENSE_RANK()
                OVER(
                    ORDER BY
                        m.badge_nbr
                )                         meter_count,
                br.reg_const              multiplier,
                trunc(br.start_read_dttm) prev_reading_date,
                trunc(br.end_read_dttm)   curr_reading_date,
                br.start_reg_reading      prev_rdg,
                br.end_reg_reading        curr_rdg,
                br.msr_qty                reg_cons,
                br.sp_id,
                br.final_uom_cd           uom,
                r.consum_sub_flg
            FROM
                ci_bseg      bs,
                ci_bseg_read br,
                ci_reg_read  rr,
                ci_reg       r,
                ci_mtr       m
            WHERE
                    bs.bseg_id = br.bseg_id
                AND br.start_reg_read_id = rr.reg_read_id
                AND rr.reg_id = r.reg_id
                AND m.mtr_id = r.mtr_id
                AND bs.bseg_stat_flg IN ( '50', '70' )
                AND bs.bill_id = p_bill_id
                AND bs.sa_id = p_sa_id
                AND br.usage_flg = '+'
            ORDER BY
                br.start_read_dttm DESC
        ) LOOP
            l_unmetered_sa := false;
            IF r.uom = 'KWH' THEN
                -- get pole no from ci_sp_geo
                l_md.pole_no := get_pole_no(r.sp_id);

                -- get connected load
                l_md.conn_load := get_bill_sq(p_bill_id, p_sa_id, 'BILLCNLD', 'W');
                IF l_md.conn_load IS NULL THEN
                    l_md.conn_load := get_bill_sq(p_bill_id, p_sa_id, 'CONNLOAD', 'W');
                END IF;

                BEGIN
                    --               DBMS_OUTPUT.put_line('p_tran_no:' || p_tran_no ||
                    --                           '; meter_count:' || r.meter_count ||
                    --                           '; badge_nbr:' || r.badge_nbr ||
                    --                           '; serial_nbr:' || r.serial_nbr ||
                    --                           '; pole_no:' || l_md.pole_no ||
                    --                           '; conn_load:' || l_md.conn_load ||
                    --                           '; multiplier:' || r.multiplier ||
                    --                           '; prev_reading_date:' || r.prev_reading_date ||
                    --                           '; curr_reading_date:' || r.curr_reading_date ||
                    --                           '; prev_rdg:' || r.prev_rdg ||
                    --                           '; curr_rdg:' || r.curr_rdg ||
                    --                           '; reg_cons:' || r.reg_cons ||
                    --                           '; consum_sub_flg:' || r.consum_sub_flg);

                    INSERT INTO bp_meter_details (
                        tran_no,
                        meter_count,
                        badge_no,
                        serial_no,
                        pole_no,
                        conn_load,
                        multiplier,
                        prev_reading_date,
                        curr_reading_date,
                        prev_kwhr_rdg,
                        curr_kwhr_rdg,
                        reg_kwhr_cons,
                        kwhr_consum_sub_flg
                    ) VALUES (
                        p_tran_no,
                        r.meter_count,
                        r.badge_nbr,
                        r.serial_nbr,
                        l_md.pole_no,
                        l_md.conn_load,
                        r.multiplier,
                        r.prev_reading_date,
                        r.curr_reading_date,
                        r.prev_rdg,
                        r.curr_rdg,
                        r.reg_cons,
                        r.consum_sub_flg
                    );

                EXCEPTION
                    WHEN dup_val_on_index THEN
                        BEGIN
                            UPDATE bp_meter_details
                            SET
                                pole_no = l_md.pole_no,
                                conn_load = l_md.conn_load,
                                multiplier = r.multiplier,
                                prev_reading_date = r.prev_reading_date,
                                curr_reading_date = r.curr_reading_date,
                                prev_kwhr_rdg = r.prev_rdg,
                                curr_kwhr_rdg = r.curr_rdg,
                                reg_kwhr_cons = r.reg_cons,
                                kwhr_consum_sub_flg = r.consum_sub_flg
                            WHERE
                                    tran_no = p_tran_no
                                AND meter_count = r.meter_count
                                AND badge_no = r.badge_nbr;

                        END;
                    WHEN OTHERS THEN
                        log_error('Insert to meter details - kwhr', sqlerrm, NULL, 'BP_METER_DETAILS', p_tran_no,
                                 p_bill_id, NULL);
                        dbms_application_info.set_action('Error Encountered.');
                END;

            END IF;

            IF r.uom = 'KW' THEN
                -- get pole no from ci_sp_geo
                l_md.pole_no := get_pole_no(r.sp_id);
                l_md.meter_count := l_md.meter_count + 1;
                BEGIN
                    INSERT INTO bp_meter_details (
                        tran_no,
                        meter_count,
                        badge_no,
                        serial_no,
                        pole_no,
                        multiplier,
                        prev_reading_date,
                        curr_reading_date,
                        prev_demand_rdg,
                        curr_demand_rdg,
                        reg_demand_cons,
                        demand_consum_sub_flg
                    ) VALUES (
                        p_tran_no,
                        r.meter_count,
                        r.badge_nbr,
                        r.serial_nbr,
                        l_md.pole_no,
                        r.multiplier,
                        r.prev_reading_date,
                        r.curr_reading_date,
                        r.prev_rdg,
                        r.curr_rdg,
                        r.reg_cons,
                        r.consum_sub_flg
                    );

                EXCEPTION
                    WHEN dup_val_on_index THEN
                        BEGIN
                            UPDATE bp_meter_details
                            SET
                                pole_no = l_md.pole_no,
                                multiplier = r.multiplier,
                                prev_reading_date = r.prev_reading_date,
                                curr_reading_date = r.curr_reading_date,
                                prev_demand_rdg = r.prev_rdg,
                                curr_demand_rdg = r.curr_rdg,
                                reg_demand_cons = r.reg_cons,
                                demand_consum_sub_flg = r.consum_sub_flg
                            WHERE
                                    tran_no = p_tran_no
                                AND meter_count = r.meter_count
                                AND badge_no = r.badge_nbr;

                        END;
                    WHEN OTHERS THEN
                        dbms_application_info.set_action('Error Encountered.');
                        log_error('Insert to meter details - kw', sqlerrm, NULL, 'BP_METER_DETAILS', p_tran_no,
                                 p_bill_id, NULL);
                END;

            END IF;

            IF r.uom = 'KVAR' THEN
                -- get pole no from ci_sp_geo
                l_md.pole_no := get_pole_no(r.sp_id);
                BEGIN
                    INSERT INTO bp_meter_details (
                        tran_no,
                        meter_count,
                        badge_no,
                        serial_no,
                        pole_no,
                        multiplier,
                        prev_reading_date,
                        curr_reading_date,
                        prev_kvar_rdg,
                        curr_kvar_rdg,
                        reg_kvar_cons,
                        kvar_consum_sub_flg
                    ) VALUES (
                        p_tran_no,
                        r.meter_count,
                        r.badge_nbr,
                        r.serial_nbr,
                        l_md.pole_no,
                        r.multiplier,
                        r.prev_reading_date,
                        r.curr_reading_date,
                        r.prev_rdg,
                        r.curr_rdg,
                        r.reg_cons,
                        r.consum_sub_flg
                    );

                EXCEPTION
                    WHEN dup_val_on_index THEN
                        BEGIN
                            UPDATE bp_meter_details
                            SET
                                pole_no = l_md.pole_no,
                                multiplier = r.multiplier,
                                prev_reading_date = r.prev_reading_date,
                                curr_reading_date = r.curr_reading_date,
                                prev_kvar_rdg = r.prev_rdg,
                                curr_kvar_rdg = r.curr_rdg,
                                reg_kvar_cons = r.reg_cons,
                                kvar_consum_sub_flg = r.consum_sub_flg
                            WHERE
                                    tran_no = p_tran_no
                                AND meter_count = r.meter_count
                                AND badge_no = r.badge_nbr;

                        END;
                    WHEN OTHERS THEN
                        dbms_application_info.set_action('Error Encountered.');
                        log_error('Insert to meter details - kvar', sqlerrm, NULL, 'BP_METER_DETAILS', p_tran_no,
                                 p_bill_id, NULL);
                END;

            END IF;

        END LOOP;

        -- if no meter data is found from the bseg_read
        -- assume s.a. is unmetered, so insert dummy meter data
        IF l_unmetered_sa THEN
            l_md.meter_count := 1;
            l_md.badge_no := 'UNMETERED';
            l_md.prev_reading_date := last_day(add_months(p_bill_dt, -1));
            l_md.curr_reading_date := last_day(p_bill_dt);
            l_md.conn_load := get_bill_sq(p_bill_id, p_sa_id, 'BILLW', 'W');
            l_md.prev_kwhr_rdg := 0;
            l_md.curr_kwhr_rdg := 0;
            BEGIN
                INSERT INTO bp_meter_details (
                    tran_no,
                    meter_count,
                    badge_no,
                    conn_load,
                    prev_reading_date,
                    curr_reading_date,
                    prev_kwhr_rdg,
                    curr_kwhr_rdg
                ) VALUES (
                    p_tran_no,
                    l_md.meter_count,
                    l_md.badge_no,
                    l_md.conn_load,
                    l_md.prev_reading_date,
                    l_md.curr_reading_date,
                    l_md.prev_kwhr_rdg,
                    l_md.curr_kwhr_rdg
                );

            EXCEPTION
                WHEN OTHERS THEN
                    dbms_application_info.set_action('Error Encountered.');
                    log_error('Insert to meter details - unmetered', sqlerrm, NULL, 'BP_METER_DETAILS', p_tran_no,
                             p_bill_id, NULL);
            END;

        END IF;

    END;

    PROCEDURE insert_consumption_hist (
        p_tran_no   IN NUMBER, --p_sa_id in varchar2,
        p_acct_id   IN VARCHAR2,
        p_bill_date IN DATE
    ) IS
    BEGIN
        BEGIN
            INSERT INTO bp_consumption_hist (
                tran_no,
                rdg_date,
                consumption
            )
                ( SELECT
                    p_tran_no,
                    trunc(rdg_date) rdg_date,
                    SUM(consumption)
                FROM
                    (
                        SELECT DISTINCT
                            bs.end_dt   rdg_date,
                            bsq.bill_sq consumption
                        FROM
                            ci_bseg    bs,
                            ci_bseg_sq bsq,
                            ci_sa      sa,
                            ci_sa_type sat
                        WHERE
                                bs.bseg_id = bsq.bseg_id
                            AND sa.sa_id = bs.sa_id
                            AND sa.sa_type_cd = sat.sa_type_cd
                            AND sat.dst_id = 'AR-ELC    '
                            AND sat.allow_sp_sw = 'Y'
                            AND bsq.sqi_cd = rpad('BILLKWH', 8)
                            AND bs.bseg_stat_flg IN ( '50', '70' )
                               --and    bs.sa_id      = p_sa_id
                            AND sa.acct_id = p_acct_id
                            AND bs.end_dt <= p_bill_date
                            AND bs.end_dt >= add_months(trunc(p_bill_date, 'MM'), - 12)
                        ORDER BY
                            bs.end_dt DESC
                    )
                WHERE
                    ROWNUM <= 13
                GROUP BY
                    trunc(rdg_date)
                );

        EXCEPTION
            WHEN OTHERS THEN
                log_error('Populating Cons. Hist.', sqlerrm, NULL, 'BP_CONSUMPTION_HIST', p_tran_no,
                         p_acct_id, to_char(p_bill_date, 'MM/DD/YYYY'));

                dbms_application_info.set_action('Error Encountered.');
        END;
    END;

    PROCEDURE insert_flt_consumption_hist (
        p_tran_no   IN NUMBER,
        p_acct_id   IN VARCHAR2,
        p_bill_date IN DATE
    ) IS
    BEGIN
        BEGIN
            INSERT INTO bp_consumption_hist (
                tran_no,
                rdg_date,
                consumption
            )
                ( SELECT
                    p_tran_no,
                    trunc(rdg_date) rdg_date,
                    SUM(consumption)
                FROM
                    (
                        SELECT DISTINCT
                            bs.end_dt   rdg_date,
                            bsq.bill_sq consumption
                        FROM
                            ci_bseg    bs,
                            ci_bseg_sq bsq,
                            ci_sa      sa,
                            ci_sa_type sat
                        WHERE
                                bs.bseg_id = bsq.bseg_id
                            AND sa.sa_id = bs.sa_id
                            AND sa.sa_type_cd = sat.sa_type_cd
                            AND sat.dst_id = 'AR-ELC    '
                            AND sat.allow_sp_sw = 'Y'
                            AND bsq.sqi_cd = rpad('FLTKWH', 8)
                            AND bs.bseg_stat_flg IN ( '50', '70' )
                               --and    bs.sa_id      = p_sa_id
                            AND sa.acct_id = p_acct_id
                            AND bs.end_dt <= last_day(p_bill_date)
                            AND bs.end_dt >= add_months(trunc(p_bill_date, 'MM'), - 12)
                        ORDER BY
                            bs.end_dt DESC
                    )
                WHERE
                    ROWNUM <= 13
                GROUP BY
                    trunc(rdg_date)
                );

        EXCEPTION
            WHEN OTHERS THEN
                log_error('Populating Cons. Hist.', sqlerrm, NULL, 'BP_CONSUMPTION_HIST', p_tran_no,
                         p_acct_id, to_char(p_bill_date, 'MM/DD/YYYY'));

                dbms_application_info.set_action('Error Encountered.');
        END;
    END;

    PROCEDURE add_detail_line (
        p_tran_no     IN NUMBER,
        p_line_code   IN VARCHAR2,
        p_line_rate   IN VARCHAR2,
        p_line_amount IN NUMBER
    ) IS
    BEGIN
        BEGIN
            INSERT INTO bp_details (
                tran_no,
                line_code,
                line_rate,
                line_amount
            ) VALUES (
                p_tran_no,
                p_line_code,
                p_line_rate,
                p_line_amount
            );

        EXCEPTION
            WHEN dup_val_on_index THEN
                BEGIN
                    UPDATE bp_details
                    SET
                        line_amount = line_amount + p_line_amount
                    WHERE
                            tran_no = p_tran_no
                        AND line_code = p_line_code;

                EXCEPTION
                    WHEN OTHERS THEN
                        dbms_application_info.set_action('Error Encountered.');
                        raise_application_error(-20136, sqlerrm);
                END;
            WHEN OTHERS THEN
                dbms_application_info.set_action('Error Encountered.');
                log_error('Adding Detail Line', sqlerrm, NULL, 'BP_DETAILS', p_tran_no,
                         p_line_code, NULL);
        END;
    END;

    PROCEDURE adjust_dr_cr_line (
        p_tran_no IN NUMBER,
        p_bill_no IN VARCHAR2,
        p_sa_id   IN VARCHAR2
    ) AS
        l_adj       NUMBER;
        l_ec_uc_adj NUMBER;
        l_bd_amt    number; --02/28/2024
    BEGIN
        --getting ec/uc adjustments
        SELECT
            nvl(SUM(line_amount), 0)
        INTO l_ec_uc_adj
        FROM
            bp_details
        WHERE
                tran_no = p_tran_no
            AND line_code IN ( 'UCEADJPD', 'UCECADJ' );

        --getting adjustments
        SELECT
            nvl(SUM(line_amount), 0)
        INTO l_adj
        FROM
            bp_details
        WHERE
                tran_no = p_tran_no
            AND line_code IN ( 'nCCBADJ', 'pCCBADJ' );

        l_adj := l_adj + l_ec_uc_adj;
        DELETE FROM bp_details
        WHERE
                tran_no = p_tran_no
            AND line_code IN ( 'UCEADJPD', 'UCECADJ', 'nCCBADJ', 'pCCBADJ' );

        DECLARE
            l_oth_surcharge NUMBER;
        BEGIN
            SELECT /*+RULE*/
                nvl(SUM(cur_amt), 0)
            INTO l_oth_surcharge
            FROM
                ci_ft
            WHERE
                    bill_id = p_bill_no
                AND ft_type_flg IN ( 'AD', 'AX' )
                AND parent_id = 'SURCHADJ'
                AND sa_id != p_sa_id;

            l_adj := l_adj + l_oth_surcharge;
        END;
        

        IF ( l_adj <> 0 ) THEN
            IF ( l_adj > 0 ) THEN
                --insert positive adjustment pccbadj
                add_detail_line(p_tran_no, 'pCCBADJ', NULL, l_adj);
            ELSIF ( l_adj < 0 ) THEN
                --insert negative adjustment nccbadj
                add_detail_line(p_tran_no, 'nCCBADJ', NULL, l_adj);
            END IF;
        END IF;

    END adjust_dr_cr_line;

    FUNCTION get_line_code (
        p_descr_on_bill IN VARCHAR2,
        p_sqi_code      IN VARCHAR2,
        p_bill_id       IN VARCHAR2 -- used for error reporting only
    ) RETURN VARCHAR2 IS
        l_line_code bp_detail_codes.code%TYPE;
    BEGIN
        BEGIN
            IF p_descr_on_bill = 'Lifeline Discount' THEN
                l_line_code := 'LFL-D';
            ELSIF p_descr_on_bill = 'Lifeline Discount Fix' THEN
                l_line_code := 'LFL-D-F';
            ELSE
                SELECT
                    code
                INTO l_line_code
                FROM
                    bp_detail_codes
                WHERE
                    p_descr_on_bill LIKE nvl(ccnb_descr_on_bill, '00')
                                         || '%'
                    AND nvl(ccnb_sqi_cd, '0') = nvl(p_sqi_code, '0');

            END IF;
        EXCEPTION
            WHEN too_many_rows THEN
                log_error(p_descr_on_bill
                          || ' '
                          || p_sqi_code
                          || ' '
                          || p_bill_id, sqlerrm, 'More than one row found.', NULL, NULL,
                         NULL, NULL);

                raise_application_error(-20150, 'More than 1 row found for '
                                                || p_descr_on_bill
                                                || ' '
                                                || p_sqi_code
                                                || ' '
                                                || p_bill_id);

            WHEN no_data_found THEN
                log_error(p_descr_on_bill
                          || ' '
                          || p_sqi_code
                          || ' '
                          || p_bill_id, sqlerrm, 'Calc line not found in bp_detail_codes', NULL, NULL,
                         NULL, NULL);

                raise_application_error(-20155, p_descr_on_bill
                                                || ' '
                                                || p_sqi_code
                                                || ' '
                                                || p_bill_id
                                                || ' is not found.');

            WHEN OTHERS THEN
                dbms_application_info.set_action('Error Encountered.');
                raise_application_error(-20160, sqlerrm);
        END;

        RETURN ( l_line_code );
    END;

    FUNCTION get_par_value (
        p_descr_on_bill IN VARCHAR2
    ) RETURN NUMBER AS
        l_val    VARCHAR2(20);
        l_offset NUMBER;
    BEGIN
        l_offset := instr(p_descr_on_bill, '(Rate:');
        IF l_offset > 0 THEN
            l_val := replace(substr(p_descr_on_bill, l_offset + 6), ')', NULL);

            l_val := replace(l_val, '%', NULL);
        END IF;

        RETURN round(to_number(l_val), 2);
    END get_par_value;

    FUNCTION get_par_line_rate (
        p_line_code     IN VARCHAR2,
        p_descr_on_bill IN VARCHAR2
    ) RETURN VARCHAR2 AS
        l_line_rate VARCHAR2(100);
        l_uom_cd    VARCHAR2(100);
    BEGIN
        BEGIN
            SELECT
                regular_desc
            INTO l_uom_cd
            FROM
                bp_detail_codes
            WHERE
                code = p_line_code;

        EXCEPTION
            WHEN OTHERS THEN
                dbms_application_info.set_action('Error Encountered.');
                raise_application_error(-20170, sqlerrm);
        END;

        DECLARE
            l_val NUMBER(18, 7);
        BEGIN
            l_val := get_par_value(p_descr_on_bill);
            l_line_rate := to_char(l_val, 'fm99,990.00')
                           || '% x 0.30/'
                           || l_uom_cd;
        END;

        RETURN l_line_rate;
    END get_par_line_rate;

    FUNCTION get_rep_par_value (
        p_tran_no IN NUMBER
    ) RETURN NUMBER AS
        l_line_rate VARCHAR2(300);
        l_val       VARCHAR2(100);
        l_rate      NUMBER;
    BEGIN
        BEGIN
            SELECT
                line_rate
            INTO l_line_rate
            FROM
                bp_details
            WHERE
                    tran_no = p_tran_no
                AND line_code = 'PAR';

        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;

        l_val := replace(l_line_rate, '% x 0.30/kWh', NULL);
        l_rate := round(to_number(l_val), 2);
        RETURN l_rate;
    END get_rep_par_value;

    FUNCTION get_par_kwh (
        p_bill_id IN VARCHAR2
    ) RETURN NUMBER AS
        l_calc_amt NUMBER(15, 2);
    BEGIN
        BEGIN
            SELECT
                calc_amt
            INTO l_calc_amt
            FROM
                ci_bseg_calc_ln calc,
                ci_bseg         bseg
            WHERE
                    calc.bseg_id = bseg.bseg_id
                AND bill_id = p_bill_id
                AND bseg.bseg_stat_flg IN ( '50', '70' ) -->> v1.3.6
                AND calc.descr_on_bill = 'FCPO: PAR KWH';

        EXCEPTION
            WHEN no_data_found THEN
                l_calc_amt := 0;
            WHEN OTHERS THEN
                log_error('GET_PAR_KWH ' || p_bill_id, sqlerrm, 'Error in retrieving PAR amount', NULL, NULL,
                         NULL, NULL);

                l_calc_amt := 0;
        END;

        RETURN l_calc_amt;
    END;

    FUNCTION get_par_month (
        p_sa_id      IN VARCHAR2,
        p_bill_month IN DATE
    ) RETURN DATE AS
        l_date DATE;
    BEGIN
        BEGIN
            SELECT
                MAX(end_dt)
            INTO l_date
            FROM
                (
                    SELECT
                        trunc(bseg.end_dt, 'MM') end_dt,
                        acct.bill_cyc_cd,
                        DENSE_RANK()
                        OVER(
                            ORDER BY
                                trunc(bseg.end_dt, 'MM') DESC
                        )                        seq
                    FROM
                        ci_bseg bseg,
                        ci_bill bill,
                        ci_acct acct
                    WHERE
                            bseg.sa_id = p_sa_id
                          --and bseg.bseg_stat_flg = 50 -->> old v1.3.5
                        AND bseg.bseg_stat_flg IN ( '50', '70' ) -->> v1.3.6
                        AND trunc(bseg.end_dt, 'MM') < trunc(p_bill_month, 'MM')
                        AND bseg.bill_id = bill.bill_id
                        AND bill.acct_id = acct.acct_id
                        AND acct.bill_cyc_cd IN ( 'BC01', 'BC02', 'BC03', 'BC04', 'BC05',
                                                  'BC06', 'BC07', 'BC08', 'BC09', 'BC10',
                                                  'BC11', 'BC12', 'BC13', 'BC14', 'BC15',
                                                  'BC16', 'BC17', 'BC18', 'BC19', 'BC20',
                                                  'BC21', 'BC22', 'BC23', 'BC24', 'BC25' )
                ) main
            WHERE
                seq = (
                    CASE
                        WHEN main.bill_cyc_cd IN ( 'BC18', 'BC19', 'BC20', 'BC21', 'BC22',
                                                   'BC23', 'BC24', 'BC25' ) THEN
                            3
                        ELSE
                            2
                    END
                );

        EXCEPTION
            WHEN OTHERS THEN
                log_error('GET_PAR_MONTH SA ID:'
                          || p_sa_id
                          || ' Bill Month:'
                          || p_bill_month, sqlerrm, 'Error in retrieving PAR amount', NULL, NULL,
                         NULL, NULL);
        END;

        RETURN l_date;
    END;

    FUNCTION get_line_rate (
        p_line_code     IN VARCHAR2,
        p_descr_on_bill IN VARCHAR2,
        p_uom_cd        IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_line_rate VARCHAR2(100);
        l_uom_cd    VARCHAR2(100);
        l_offset    NUMBER;
    BEGIN
        BEGIN
            SELECT
                regular_desc
            INTO l_uom_cd
            FROM
                bp_detail_codes
            WHERE
                code = p_line_code;

        EXCEPTION
            WHEN OTHERS THEN
                dbms_application_info.set_action('Error Encountered.');
                raise_application_error(-20170, sqlerrm);
        END;

        l_offset := instr(p_descr_on_bill, '(Rate:P');
        IF l_offset > 0 THEN
            l_line_rate := replace(substr(p_descr_on_bill, l_offset + 7), ')', NULL)
                           || '/'
                           || l_uom_cd;
        END IF;

        RETURN ( l_line_rate );
    END;

    FUNCTION get_lpc_base_amount (
        p_sa_id      IN VARCHAR2,
        p_bill_id    IN VARCHAR2,
        p_bill_dt    IN DATE,
        p_lpc_amount IN NUMBER
    ) RETURN NUMBER IS

        CURSOR lpc_base_cur IS
        SELECT
            balance - cur_amt
        FROM
            (
                SELECT
                    ft_type_flg,
                    cur_amt,
                    ars_dt,
                    cre_dttm,
                    parent_id,
                    bill_id,
                    SUM(cur_amt)
                    OVER(PARTITION BY sa_id
                         ORDER BY
                             freeze_dttm
                    ) balance
                FROM
                    ci_ft
                WHERE
                        sa_id = p_sa_id
                    AND cur_amt <> 0
                    AND ars_dt <= p_bill_dt
                ORDER BY
                    freeze_dttm DESC
            )
        WHERE
                parent_id = 'SURCHADJ'
            AND bill_id = p_bill_id;

        l_lpc_base_amount NUMBER;
    BEGIN
        OPEN lpc_base_cur;
        FETCH lpc_base_cur INTO l_lpc_base_amount;
        CLOSE lpc_base_cur;
        IF l_lpc_base_amount IS NULL THEN
            l_lpc_base_amount := round(p_lpc_amount / 0.02, 2);
        END IF;

        RETURN ( l_lpc_base_amount );
    END;

    PROCEDURE adjust_uc_mes (
        p_bill_id IN VARCHAR2,
        p_sa_id   IN VARCHAR2,
        p_tran_no IN NUMBER
    ) AS

        --Version History
        /*--------------------------------------------------------
           v1.3.7 06-SEP-2022 GMEPIEZA
           Remarks : updated procedure UCME groupings for the new UC ME True Up
                     in relation to CM1578 DLPC UC ME True Up
        */
        --------------------------------------------------------

        l_uc_total  NUMBER;
        l_bseg_id   CHAR(12);
        l_line_rate VARCHAR2(300);
        l_uc_descr  VARCHAR2(30);
    BEGIN
        DECLARE
            l_no_uc_found EXCEPTION;
        BEGIN
            DECLARE BEGIN
                SELECT
                    cl.calc_amt,
                    cl.bseg_id,
                    'UC_ME_TOTAL'
                INTO
                    l_uc_total,
                    l_bseg_id,
                    l_uc_descr
                FROM
                    ci_bseg_calc_ln cl,
                    ci_bseg_calc    bc,
                    ci_bseg         bs
                WHERE
                        bs.bseg_id = bc.bseg_id
                    AND bc.bseg_id = cl.bseg_id
                    AND bc.header_seq = cl.header_seq
                    AND bs.bseg_stat_flg IN ( '50', '70' )
                    AND bs.bill_id = p_bill_id
                    AND bs.sa_id = p_sa_id
                    AND prt_sw = 'Y'
                    AND cl.descr_on_bill = 'UC-ME Total';

            EXCEPTION
                WHEN no_data_found THEN
                    BEGIN
                        SELECT
                            cl.calc_amt,
                            cl.bseg_id,
                            'UC_ME_SPUG'
                        INTO
                            l_uc_total,
                            l_bseg_id,
                            l_uc_descr
                        FROM
                            ci_bseg_calc_ln cl,
                            ci_bseg_calc    bc,
                            ci_bseg         bs
                        WHERE
                                bs.bseg_id = bc.bseg_id
                            AND bc.bseg_id = cl.bseg_id
                            AND bc.header_seq = cl.header_seq
                            AND bs.bseg_stat_flg IN ( '50', '70' )
                            AND bs.bill_id = p_bill_id
                            AND bs.sa_id = p_sa_id
                            AND prt_sw = 'Y'
                            AND cl.descr_on_bill = 'Universal Charge Missionary Electrification - NPC-SPUG';

                    EXCEPTION
                        WHEN no_data_found THEN
                            RAISE l_no_uc_found;
                    END;
            END;

            DECLARE
                l_descr_on_bill  VARCHAR2(80);
                l_sqi_cd         CHAR(8);
                l_offset         NUMBER;
                l_rate           NUMBER;
                l_descr_on_bill2 VARCHAR2(80);
                l_sqi_cd2        CHAR(8);
                l_rate2          NUMBER;
                l_calc_amt2      NUMBER;
                l_descr_on_bill3 VARCHAR2(80);
                l_sqi_cd3        CHAR(8);
                l_rate3          NUMBER;
                l_descr_on_bill4 VARCHAR2(80); -->>gmepieza 09/06/2022
                l_sqi_cd4        CHAR(8); -->>gmepieza 09/06/2022
                l_rate4          NUMBER; -->> gmepieza 09/06/2022
                l_descr_on_bill5 VARCHAR2(80); -->>gmepieza 06/02/2023
                l_sqi_cd5        CHAR(8); -->>gmepieza 06/02/2023
                l_rate5          NUMBER; -->> gmepieza 06/02/2023
                l_descr_on_bill6 VARCHAR2(80); -->>gmepieza 06/02/2023
                l_sqi_cd6        CHAR(8); -->>gmepieza 06/02/2023
                l_rate6          NUMBER; -->> gmepieza 06/02/2023
                l_total_rate     NUMBER;
                l_final_uom      VARCHAR2(10);
            BEGIN
                -- uc missionary electrification
                BEGIN
                    SELECT
                        descr_on_bill,
                        sqi_cd
                    INTO
                        l_descr_on_bill,
                        l_sqi_cd
                    FROM
                        ci_bseg_calc_ln
                    WHERE
                            bseg_id = l_bseg_id
                        AND descr_on_bill LIKE 'Universal Charge - Missionary Electrification' || '%';

                    l_offset := instr(l_descr_on_bill, '(Rate:P');
                    IF l_offset > 0 THEN
                        l_rate := to_number(replace(substr(l_descr_on_bill, l_offset + 7), ')', NULL));
                    END IF;

                EXCEPTION
                    WHEN no_data_found THEN
                        NULL;
                END;

                -- uc missionary electrification cash incentive for RE
                BEGIN
                    SELECT
                        descr_on_bill,
                        sqi_cd,
                        calc_amt
                    INTO
                        l_descr_on_bill2,
                        l_sqi_cd2,
                        l_calc_amt2
                    FROM
                        ci_bseg_calc_ln
                    WHERE
                            bseg_id = l_bseg_id
                        AND descr_on_bill LIKE 'Universal Charge-Missionary Electrification Cash Incentive for RE' || '%';

                    l_offset := instr(l_descr_on_bill2, '(Rate:P');
                    IF l_offset > 0 THEN
                        l_rate2 := to_number(replace(substr(l_descr_on_bill2, l_offset + 7), ')', NULL));
                    END IF;

                EXCEPTION
                    WHEN no_data_found THEN
                        NULL;
                END;

                --Universal Charge - Missionary Electrification 3 (Rate:%R)
                BEGIN
                    SELECT
                        descr_on_bill,
                        sqi_cd
                    INTO
                        l_descr_on_bill3,
                        l_sqi_cd3
                    FROM
                        ci_bseg_calc_ln
                    WHERE
                            bseg_id = l_bseg_id
                        AND descr_on_bill LIKE 'Universal Charge-Missionary Electrification 3' || '%';

                    l_offset := instr(l_descr_on_bill3, '(Rate:P');
                    IF l_offset > 0 THEN
                        l_rate3 := to_number(replace(substr(l_descr_on_bill3, l_offset + 7), ')', NULL));
                    END IF;

                EXCEPTION
                    WHEN no_data_found THEN
                        NULL;
                END;

                --Universal Charge-Missionary Electrification True Up (Rate:P0.004563) -->> gmepieza 09/06/2022
                BEGIN
                    SELECT
                        descr_on_bill,
                        sqi_cd
                    INTO
                        l_descr_on_bill4,
                        l_sqi_cd4
                    FROM
                        ci_bseg_calc_ln
                    WHERE
                            bseg_id = l_bseg_id
                        AND dst_id LIKE 'DV-UCMETU ' || '%';
                    --and    descr_on_bill like
                           --'Universal Charge-Missionary Electrification True Up' || '%';

                    l_offset := instr(l_descr_on_bill4, '(Rate:P');
                    IF l_offset > 0 THEN
                        l_rate4 := to_number(replace(substr(l_descr_on_bill4, l_offset + 7), ')', NULL));
                    END IF;

                EXCEPTION
                    WHEN no_data_found THEN
                        NULL;
                END;

                --universal charge missionary true up 2013
                BEGIN
                    SELECT
                        descr_on_bill,
                        sqi_cd
                    INTO
                        l_descr_on_bill5,
                        l_sqi_cd5
                    FROM
                        ci_bseg_calc_ln
                    WHERE
                            bseg_id = l_bseg_id
                        AND dst_id LIKE 'DV-UCMETU2' || '%';
                    --and    descr_on_bill like
                           --'Universal Charge-Missionary Electrification True Up' || '%';

                    l_offset := instr(l_descr_on_bill5, '(Rate:P');
                    IF l_offset > 0 THEN
                        l_rate5 := to_number(replace(substr(l_descr_on_bill5, l_offset + 7), ')', NULL));
                    END IF;

                EXCEPTION
                    WHEN no_data_found THEN
                        NULL;
                END;

                --universal charge missionary true up 2014
                BEGIN
                    SELECT
                        descr_on_bill,
                        sqi_cd
                    INTO
                        l_descr_on_bill6,
                        l_sqi_cd6
                    FROM
                        ci_bseg_calc_ln
                    WHERE
                            bseg_id = l_bseg_id
                        AND dst_id LIKE 'DV-UCMETU3' || '%';
                    --and    descr_on_bill like
                           --'Universal Charge-Missionary Electrification True Up' || '%';

                    l_offset := instr(l_descr_on_bill6, '(Rate:P');
                    IF l_offset > 0 THEN
                        l_rate6 := to_number(replace(substr(l_descr_on_bill6, l_offset + 7), ')', NULL));
                    END IF;

                EXCEPTION
                    WHEN no_data_found THEN
                        NULL;
                END;

                IF trim(l_sqi_cd) = 'BILLKWH' THEN
                    l_final_uom := 'kWh';
                ELSIF trim(l_sqi_cd) = 'CMBKWHT' THEN
                    l_final_uom := 'kWh';
                ELSIF trim(l_sqi_cd) = 'FLTKWH' THEN
                    l_final_uom := 'kWh';
                ELSIF trim(l_sqi_cd) = 'BILLW' THEN
                    l_final_uom := 'Watt';
                END IF;

                IF ( l_uc_descr = 'UC_ME_TOTAL' ) THEN
                    l_total_rate := nvl(l_rate, 0) + nvl(l_rate2, 0) + nvl(l_rate3, 0) + nvl(l_rate4, 0) + -->> gmepieza 09/06/2022 added l_rate4
                     nvl(l_rate5, 0) + nvl(l_rate6, 0); -->> gmepieza 06/02/2023 added l_rate5
                    l_line_rate := to_char(l_total_rate, 'fm0.09999999')
                                   || '/'
                                   || l_final_uom;
                    add_detail_line(p_tran_no, 'UC-MES', l_line_rate, l_uc_total);
                ELSIF ( l_uc_descr = 'UC_ME_SPUG' ) THEN
                    DECLARE
                        l_total_rate_spug NUMBER;
                        l_total_rate_red  NUMBER;
                    BEGIN
                        l_total_rate_spug := nvl(l_rate, 0) + nvl(l_rate3, 0) + nvl(l_rate4, 0) + -->> gmepieza 09/06/2022 added l_rate4
                         nvl(l_rate5, 0) + -->> gmepieza 06/02/2023 added l_rate5
                         nvl(l_rate6, 0);  -->> gmepieza 06/02/2023 added l_rate6
                        l_line_rate := to_char(l_total_rate_spug, 'fm0.09999999')
                                       || '/'
                                       || l_final_uom;
                        add_detail_line(p_tran_no, 'UC-ME-SPUG', l_line_rate, l_uc_total);
                        l_total_rate_red := nvl(l_rate2, 0);
                        l_line_rate := to_char(l_total_rate_red, 'fm0.09999999')
                                       || '/'
                                       || l_final_uom;
                        IF l_calc_amt2 IS NOT NULL THEN
                            add_detail_line(p_tran_no, 'UC-ME-RED', l_line_rate, l_calc_amt2);
                        END IF;

                    END;
                END IF;

                DELETE FROM bp_details
                WHERE
                        tran_no = p_tran_no
                    AND line_code IN ( 'UME-W', 'UME', 'UMERE-FLT', 'UMERE-KWH', 'UMERE-KWH-TOU',
                                       'UME-FLT', 'UMERE-W', 'UMERE-FLT3', 'UMERE-KWH3', 'UMERE-KWH-TOU3',
                                       'UMERE-W3', 'UMERE-N', 'UC-ME-TU', -->> gmepieza 09/06/2022
                                        'UCME-TU-FLT' ); -->> gmepieza 09/07/2022
            END;

        EXCEPTION
            WHEN l_no_uc_found THEN
                NULL;
        END;
    EXCEPTION
        WHEN OTHERS THEN
            log_error('ADJUST_UC_MES SA ID:'
                      || p_sa_id
                      || ' Bill id:'
                      || p_bill_id, sqlerrm, 'Error in Adjusting UC MEs', NULL, NULL,
                     NULL, NULL);
    END adjust_uc_mes;

    PROCEDURE insert_bp_details (
        p_tran_no IN NUMBER,
        p_bill_id IN VARCHAR2,
        p_bill_dt IN DATE,
        p_sa_id   IN VARCHAR2
    ) IS
        --Version History
        /*--------------------------------------------------------
           v1.2.1 16-FEB-2017 AOCARCALLAS
           Remarks : added condition => AND bseg.bseg_stat_flg = '50'
                     -- sub total for VAT
        */
        --------------------------------------------------------

        /*
        cursor calc_ln_cur
        is
           select   cl.uom_cd,
                    cl.tou_cd,
                    cl.calc_amt,
                    cl.base_amt,
                    cl.sqi_cd,
                    cl.descr_on_bill
           from     ci_bseg_calc_ln cl,
                    ci_bseg_calc bc,
                    ci_bseg bs
           where    bs.bseg_id = bc.bseg_id
           and      bc.bseg_id = cl.bseg_id
           and      bc.header_seq = cl.header_seq
           and      bc.header_seq = 1
           and      bs.bseg_stat_flg in ('50','70')
           and      bs.bill_id = p_bill_id
           and      bs.sa_id = p_sa_id
           --and      prt_sw  = 'Y'
           and      trim(cl.dst_id) is not null
           order by rc_seq;*/

        /*--============================================================================
            v1.0.7
              - sum-up the VAT Generation and VAT System Loss total
        */
        --============================================================================
        /*cursor calc_ln_cur is
        select uom_cd,
               tou_cd,
               sum(base_amt) base_amt,
               sqi_cd,
               descr_on_bill,
               sum(calc_amt) calc_amt
          from (select cl.uom_cd,
                       cl.tou_cd,
                       cl.calc_amt,
                       cl.base_amt,
                       cl.sqi_cd,
                       (case
                          when cl.descr_on_bill like 'VAT Generation - %' then
                           'VAT Generation - Total'
                          when cl.descr_on_bill like 'VAT System Loss%' then
                           'VAT System Loss - Total'
                          when cl.descr_on_bill like 'Senior Citizen Disc%' then
                           'Senior Citizen Discount'
                          else
                           cl.descr_on_bill
                        end) descr_on_bill
                  from ci_bseg_calc_ln cl, ci_bseg_calc bc, ci_bseg bs
                 where bs.bseg_id = bc.bseg_id
                   and bc.bseg_id = cl.bseg_id
                   and bc.header_seq = cl.header_seq
                   and bc.header_seq = 1
                   and bs.bseg_stat_flg in ('50', '70')
                   and bs.bill_id = p_bill_id
                   and bs.sa_id = p_sa_id
                      --and      prt_sw  = 'Y'
                   and trim(cl.dst_id) is not null
                 order by rc_seq)
         group by uom_cd, tou_cd, sqi_cd, descr_on_bill;*/

        CURSOR calc_ln_cur IS
        SELECT
            (
                CASE
                    WHEN descr_on_bill = 'VAT Generation - Total' THEN
                        '    '
                    ELSE
                        uom_cd
                END
            )             uom_cd,
            tou_cd,
            SUM(base_amt) base_amt,
            (
                CASE
                    WHEN descr_on_bill = 'VAT Generation - Total' THEN
                        '        '
                    ELSE
                        sqi_cd
                END
            )             sqi_cd,
            descr_on_bill,
            SUM(calc_amt) calc_amt
        FROM
            (
                SELECT
                    cl.uom_cd,
                    cl.tou_cd,
                    cl.calc_amt,
                    cl.base_amt,
                    cl.sqi_cd,
                    (
                        CASE
                            WHEN cl.descr_on_bill LIKE 'VAT Generation - %'
                                 OR cl.descr_on_bill = 'VAT NPC/PSALM Adjustment' THEN
                                'VAT Generation - Total'
                            WHEN cl.descr_on_bill LIKE 'VAT System Loss%' THEN
                                'VAT System Loss - Total'
                            WHEN cl.descr_on_bill LIKE 'Senior Citizen Disc%' THEN
                                'Senior Citizen Discount'
                            ELSE
                                cl.descr_on_bill
                        END
                    ) descr_on_bill
                FROM
                    ci_bseg_calc_ln cl,
                    ci_bseg_calc    bc,
                    ci_bseg         bs
                WHERE
                        bs.bseg_id = bc.bseg_id
                    AND bc.bseg_id = cl.bseg_id
                    AND bc.header_seq = cl.header_seq
                    AND bc.header_seq = 1
                    AND bs.bseg_stat_flg IN ( '50', '70' )
                    AND bs.bill_id = p_bill_id
                    AND bs.sa_id = p_sa_id
                          --and      prt_sw  = 'Y'
                    AND TRIM(cl.dst_id) IS NOT NULL
                ORDER BY
                    rc_seq
            )
        GROUP BY
            (
                CASE
                    WHEN descr_on_bill = 'VAT Generation - Total' THEN
                        '    '
                    ELSE
                        uom_cd
                END
            ),
            tou_cd,
            (
                CASE
                    WHEN descr_on_bill = 'VAT Generation - Total' THEN
                        '        '
                    ELSE
                        sqi_cd
                END
            ),
            descr_on_bill;

        TYPE cl_tab_type IS
            TABLE OF calc_ln_cur%rowtype INDEX BY BINARY_INTEGER;
        l_cl         cl_tab_type;
        l_row        PLS_INTEGER;
        l_bpd        bp_details%rowtype;
        l_lpc_amount NUMBER;
        l_bill_sq    NUMBER;
    BEGIN
        OPEN calc_ln_cur;
        LOOP
            FETCH calc_ln_cur
            BULK COLLECT INTO l_cl LIMIT 50;
            l_row := l_cl.first;
            WHILE ( l_row IS NOT NULL ) LOOP
                l_bpd.line_code := get_line_code(l_cl(l_row).descr_on_bill, trim(l_cl(l_row).sqi_cd), p_bill_id);

                IF l_bpd.line_code IN ( 'SLF-D' ) THEN
                    l_bpd.line_rate := to_char(round(l_cl(l_row).calc_amt / l_cl(l_row).base_amt, 2), 'fm999,990.999999')
                                       || ' of '
                                       || to_char(l_cl(l_row).base_amt, 'fm999,999,999,990.00');

                ELSIF l_bpd.line_code IN ( 'PAR' ) THEN
                    l_bpd.line_rate := get_par_line_rate(l_bpd.line_code, l_cl(l_row).descr_on_bill);
                ELSIF l_bpd.line_code IN ( 'P-R-SCDISC' ) THEN
                    l_bpd.line_rate := c_sc_disc_percent_sign
                                       || ' of '
                                       || to_char(abs(round(l_cl(l_row).calc_amt / c_sc_disc_percent, 2)), 'fm999,999,999,990.00');
                ELSIF l_bpd.line_code IN ( 'LFL-D' ) THEN
                    l_bpd.line_rate := NULL;
                ELSIF l_bpd.line_code IN ( 'LFL-D-F' ) THEN
                    l_bpd.line_rate := NULL;
                ELSE
                    l_bpd.line_rate := get_line_rate(l_bpd.line_code, l_cl(l_row).descr_on_bill, trim(l_cl(l_row).uom_cd));
                END IF;

                add_detail_line(p_tran_no, l_bpd.line_code, l_bpd.line_rate, l_cl(l_row).calc_amt);

                l_row := l_cl.next(l_row);
            END LOOP;

            EXIT WHEN calc_ln_cur%notfound;
        END LOOP;

        CLOSE calc_ln_cur;

        -- add surcharge / late payment charge
        --l_lpc_amount := get_bill_sq (p_bill_id, p_sa_id, 'ADJLPC');
        l_lpc_amount := get_lpc(p_bill_id, p_sa_id);

        -- modified by BCC
        -- Oct. 26, 2011
        -- there's a need to get the actual base amount for lpc
        /*if l_lpc_amount > 0
        then
           add_detail_line (p_tran_no,
                            'ADJLPC',
                            '0.02 of ' || to_char(round(l_lpc_amount/0.02, 2),'fm999,999,999,990.00'),
                            l_lpc_amount);
        end if;*/

        IF l_lpc_amount > 0 THEN
            add_detail_line(p_tran_no, 'ADJLPC', '2% of '
                                                 || to_char(get_lpc_base_amount(p_sa_id, p_bill_id, p_bill_dt, l_lpc_amount), 'fm999,999,999,990.00'),
                                                 l_lpc_amount);
        END IF;

        --line rate for Lifeline Discount
        DECLARE
            l_lfl_d     NUMBER(1);
            l_lfl_line  NUMBER;
            l_line_rate VARCHAR(300);
        BEGIN
            SELECT
                1
            INTO l_lfl_d
            FROM
                bp_details
            WHERE
                    tran_no = p_tran_no
                AND line_code = 'LFL-D';

            SELECT
                SUM(substr(line_rate, 1, instr(line_rate, '/') - 1))
            INTO l_lfl_line
            FROM
                bp_details
            WHERE
                    tran_no = p_tran_no
                AND line_code IN ( 'GEN', 'TRX-KWH', 'SYS', 'DIST', 'SVR',
                                   'MVR' );

            BEGIN
                SELECT
                    sq.bill_sq
                INTO l_bill_sq
                FROM
                    ci_bseg    bseg,
                    ci_bseg_sq sq
                WHERE
                        bseg.bseg_id = sq.bseg_id
                    AND bseg.bill_id = p_bill_id
                    AND bseg.bseg_stat_flg IN ( '50', '70' ) -->> v1.3.6
                    AND sqi_cd = 'SLFDISC ';

                l_line_rate := to_char(l_bill_sq)
                               || '% x '
                               || to_char(l_lfl_line)
                               || '/kWh';

                UPDATE bp_details
                SET
                    line_rate = l_line_rate
                WHERE
                        tran_no = p_tran_no
                    AND line_code = 'LFL-D';

                --line rate for Lifeline Discount Fix
                DECLARE
                    l_lfl_f NUMBER(1);
                    l_mfx   VARCHAR2(10);
                BEGIN
                    SELECT
                        1
                    INTO l_lfl_f
                    FROM
                        bp_details
                    WHERE
                            tran_no = p_tran_no
                        AND line_code = 'LFL-D-F';

                    BEGIN
                        SELECT
                            substr(line_rate, 1, instr(line_rate, '/') - 1)
                        INTO l_mfx
                        FROM
                            bp_details
                        WHERE
                                tran_no = p_tran_no
                            AND line_code IN ( 'MFX', 'MFX-R' );

                        IF l_mfx IS NOT NULL THEN
                            UPDATE bp_details
                            SET
                                line_rate = to_char(l_bill_sq)
                                            || '% x '
                                            || l_mfx
                                            || '/month'
                            WHERE
                                    tran_no = p_tran_no
                                AND line_code = 'LFL-D-F';

                        END IF;

                    EXCEPTION
                        WHEN no_data_found THEN
                            NULL;
                    END;

                EXCEPTION
                    WHEN no_data_found THEN
                        NULL;
                END;

            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;

        EXCEPTION
            WHEN no_data_found THEN
                NULL;
            WHEN OTHERS THEN
                log_error(p_bill_id, sqlerrm, 'line rate for Lifeline Discounts', NULL, NULL,
                         NULL, NULL);
        END;

        --line rate for Senior Citizen Discount
        DECLARE
            l_scd_found NUMBER(1);
            l_line_rate VARCHAR2(300);
            l_scd       NUMBER;
        BEGIN
            SELECT
                1
            INTO l_scd_found
            FROM
                bp_details
            WHERE
                    tran_no = p_tran_no
                AND line_code = 'P-R-SCDISC';

            SELECT
                SUM(line_amount)
            INTO l_scd
            FROM
                bp_details
            WHERE
                    tran_no = p_tran_no
                AND line_code IN ( 'GEN', 'GEN-FLT', 'GEN-W', 'TRX-W', 'TRX-KWH',
                                   'TRX-KW', 'TRX-FLT', 'SYS-W', 'SYS', 'SYS-FLT',
                                   'DIST-W', 'DIST2', 'DIST', 'DIST3', 'DIST-FLT',
                                   'SVR-W', 'SVR', 'SFX', 'SFX-R', 'SFX-FLT',
                                   'MVR-W', 'MVR', 'MFX', 'MFX-R', 'LFL-D-F',
                                   'LFL-D' );

            l_line_rate := c_sc_disc_percent_sign
                           || ' of '
                           || to_char(abs(l_scd), 'fm999,999,999,990.00');

            UPDATE bp_details
            SET
                line_rate = l_line_rate
            WHERE
                    tran_no = p_tran_no
                AND line_code = 'P-R-SCDISC';

        EXCEPTION
            WHEN no_data_found THEN
                NULL;
            WHEN OTHERS THEN
                log_error(p_bill_id, sqlerrm, 'line rate for Senior Citizen Discounts', NULL, NULL,
                         NULL, NULL);
        END;

        -- UC missionary adjustments
        adjust_uc_mes(p_bill_id, p_sa_id, p_tran_no);

        -- add sub totals
        BEGIN
            INSERT INTO bp_details (
                tran_no,
                line_code,
                line_amount
            )
                ( SELECT
                    bpd.tran_no,
                    bpc.summary_group,
                    SUM(line_amount)
                FROM
                    bp_details      bpd,
                    bp_detail_codes bpc
                WHERE
                        bpd.line_code = bpc.code
                    AND bpd.tran_no = p_tran_no
                    AND bpc.summary_group IS NOT NULL
                GROUP BY
                    bpd.tran_no,
                    bpc.summary_group
                );

        END;

        -- sub total for VAT
        INSERT INTO bp_details (
            tran_no,
            line_code,
            line_amount
        )
            ( SELECT
                p_tran_no,
                'vVATTOT',
                MAX(calc.calc_amt)
            FROM
                ci_bseg_calc_ln calc,
                ci_bseg         bseg
            WHERE
                    calc.bseg_id = bseg.bseg_id
                AND bseg.bill_id = p_bill_id
                AND calc.descr_on_bill = 'VAT Total'
                   --and bseg.bseg_stat_flg = '50' -->> old v1.3.5
                AND bseg.bseg_stat_flg IN ( '50', '70' ) -->> v1.3.6
            );

        -- add header info
        add_detail_line(p_tran_no, 'PREVAMTSPACER', NULL, NULL);
        add_detail_line(p_tran_no, 'CURCHARGES', NULL, NULL);
        add_detail_line(p_tran_no, 'vGENCHGHDR', NULL, NULL);
        add_detail_line(p_tran_no, 'vDISTREVHDR', NULL, NULL);
        add_detail_line(p_tran_no, 'vOTHHDR', NULL, NULL);
        add_detail_line(p_tran_no, 'vGOVREVHDR', NULL, NULL);
        add_detail_line(p_tran_no, 'vVATHDR', NULL, NULL);
        add_detail_line(p_tran_no, 'vUNIVCHGHDR', NULL, NULL);
        add_detail_line(p_tran_no, 'NETSPACER', NULL, NULL);
    END;
    
    PROCEDURE insert_bd_bseg (
        p_tran_no IN NUMBER,
        p_bill_id IN VARCHAR2
    ) IS
    BEGIN
        BEGIN
            INSERT INTO bp_details (
                tran_no,
                line_code,
                line_amount
            )
                ( SELECT
                    p_tran_no,
                    'BDSA', --TRIM(sa.sa_type_cd),
                    SUM(bc.calc_amt)
                FROM
                    ci_bseg      bs,
                    ci_sa        sa,
                    ci_sa_type   st,
                    ci_bseg_calc bc
                WHERE
                        bs.sa_id = sa.sa_id
                    AND st.sa_type_cd = sa.sa_type_cd
                    AND bs.bseg_id = bc.bseg_id
                    AND bs.bseg_stat_flg IN ( '50', '70' ) -- Frozen/OK
                    AND st.bill_seg_type_cd IN ( 'REC-TATB' )
                    AND st.sa_type_cd = 'D-BILL  '
                    AND bc.header_seq = 1
                    AND bs.bill_id = p_bill_id
                GROUP BY
                    p_tran_no,
                    sa.sa_type_cd
                );

        EXCEPTION
            WHEN OTHERS THEN
                dbms_application_info.set_action('Error Encountered.');
                raise_application_error(-20171, p_bill_id
                                                || ' '
                                                || sqlerrm);
        END;
    END;


    PROCEDURE insert_other_bseg (
        p_tran_no IN NUMBER,
        p_bill_id IN VARCHAR2
    ) IS
    BEGIN
        BEGIN
            INSERT INTO bp_details (
                tran_no,
                line_code,
                line_amount
            )
                ( SELECT
                    p_tran_no,
                    TRIM(sa.sa_type_cd),
                    SUM(bc.calc_amt)
                FROM
                    ci_bseg      bs,
                    ci_sa        sa,
                    ci_sa_type   st,
                    ci_bseg_calc bc
                WHERE
                        bs.sa_id = sa.sa_id
                    AND st.sa_type_cd = sa.sa_type_cd
                    AND bs.bseg_id = bc.bseg_id
                    AND bs.bseg_stat_flg IN ( '50', '70' ) -- Frozen/OK
                    AND st.bill_seg_type_cd IN ( 'RECUR-AS', 'BCHG-DFT' )
                    AND bc.header_seq = 1
                    AND bs.bill_id = p_bill_id
                GROUP BY
                    p_tran_no,
                    sa.sa_type_cd
                );

        EXCEPTION
            WHEN OTHERS THEN
                dbms_application_info.set_action('Error Encountered.');
                raise_application_error(-20171, p_bill_id
                                                || ' '
                                                || sqlerrm);
        END;
    END;

    PROCEDURE insert_other_bseg2 (
        p_tran_no IN NUMBER,
        p_bill_id IN VARCHAR2
    ) IS
    BEGIN
        BEGIN
            INSERT INTO bp_details (
                tran_no,
                line_code,
                line_amount
            )
                ( SELECT
                    p_tran_no,
                    TRIM(sa.sa_type_cd),
                    SUM(ft.cur_amt)
                FROM
                    ci_ft      ft,
                    ci_sa      sa,
                    ci_sa_type st
                WHERE
                        ft.sa_id = sa.sa_id
                    AND st.sa_type_cd = sa.sa_type_cd
                    AND st.bill_seg_type_cd IN ( 'RECUR-AS', 'BCHG-DFT' )
                       --and    ft_type_flg not in ('PS', 'PX', 'AD', 'AX')
                    AND ( ft_type_flg = 'BS'
                          OR ( ft_type_flg = 'BX'
                               AND ft.parent_id = ft.bill_id ) )
                    AND ft.bill_id = p_bill_id
                GROUP BY
                    sa.sa_type_cd,
                    p_tran_no
                );

        EXCEPTION
            WHEN OTHERS THEN
                dbms_application_info.set_action('Error Encountered.');
                raise_application_error(-20172, p_bill_id
                                                || ' '
                                                || sqlerrm);
        END;
    END;

    FUNCTION get_other_bseg_amt (
        p_bill_id IN VARCHAR2
    ) RETURN NUMBER IS
        l_other_bseg_amt NUMBER;
    BEGIN
        BEGIN
            SELECT
                nvl(SUM(bc.calc_amt), 0)
            INTO l_other_bseg_amt
            FROM
                ci_bseg      bs,
                ci_sa        sa,
                ci_sa_type   st,
                ci_bseg_calc bc
            WHERE
                    bs.sa_id = sa.sa_id
                AND st.sa_type_cd = sa.sa_type_cd
                AND bs.bseg_id = bc.bseg_id
                AND bs.bseg_stat_flg IN ( '50', '70' ) -- Frozen/OK
                AND st.bill_seg_type_cd IN ( 'RECUR-AS', 'BCHG-DFT' )
                AND bc.header_seq = 1
                AND bs.bill_id = p_bill_id;

        EXCEPTION
            WHEN OTHERS THEN
                l_other_bseg_amt := 0;
        END;

        RETURN ( l_other_bseg_amt );
    END;

    FUNCTION get_other_bseg_amt2 (
        p_bill_id IN VARCHAR2
    ) RETURN NUMBER IS
        l_other_bseg_amt NUMBER;
    BEGIN
        BEGIN
            SELECT
                nvl(SUM(ft.cur_amt), 0)
            INTO l_other_bseg_amt
            FROM
                ci_ft      ft,
                ci_sa      sa,
                ci_sa_type st
            WHERE
                    ft.sa_id = sa.sa_id
                AND st.sa_type_cd = sa.sa_type_cd
                AND st.bill_seg_type_cd IN ( 'RECUR-AS', 'BCHG-DFT' )
                  --and    ft_type_flg not in ('PS', 'PX')
                AND ( ft_type_flg = 'BS'
                      OR ( ft_type_flg = 'BX'
                           AND ft.parent_id = ft.bill_id ) )
                AND ft.bill_id = p_bill_id;

        EXCEPTION
            WHEN OTHERS THEN
                l_other_bseg_amt := 0;
        END;

        RETURN ( l_other_bseg_amt );
    END;

    FUNCTION get_location_code (
        p_acct_id IN VARCHAR2
    ) RETURN VARCHAR2 AS
        l_location_code VARCHAR2(71);
        l_pole_no       cm_ci_vw.pole_no%TYPE;
    BEGIN
        l_pole_no := NULL;
        BEGIN
            SELECT
                pole_no
            INTO l_pole_no
            FROM
                cm_ci_vw
            WHERE
                    acct_id = p_acct_id
                AND acct_status = 'Active';

        EXCEPTION
            WHEN no_data_found THEN
                log_error('Getting Pole no of account', NULL, 'No data found on cm_ci_vw', p_acct_id, NULL,
                         NULL);
            WHEN OTHERS THEN
                log_error('Getting Pole no of account', sqlerrm, NULL, p_acct_id, NULL,
                         NULL);
        END;

        IF l_pole_no IS NOT NULL THEN
            BEGIN
                SELECT
                    page_no
                    || '-'
                    || location_code
                INTO l_location_code
                FROM
                    virtuoso_wam_locators
                WHERE
                        plant = '01'
                    AND geocode = l_pole_no;

            EXCEPTION
                WHEN no_data_found THEN
                    l_location_code := NULL;
                WHEN OTHERS THEN
                    log_error('Getting Location code', sqlerrm, NULL, p_acct_id, l_pole_no,
                             NULL);
            END;
        END IF;

        IF l_location_code IS NULL THEN
            BEGIN
                SELECT
                    loc_code
                INTO l_location_code
                FROM
                    cm_loc_cd_mv
                WHERE
                        acct_id = p_acct_id
                    AND ROWNUM = 1;

            EXCEPTION
                WHEN no_data_found THEN
                    log_error('CM_LOC_CD_MV ' || p_acct_id, sqlerrm, 'Location Code not found in CM_LOC_CD_MV', NULL, NULL,
                             NULL, NULL);
            END;
        END IF;

        RETURN l_location_code;
    END;

    FUNCTION get_billing_cycle (
        p_acct_id IN VARCHAR2
    ) RETURN VARCHAR2 AS
        l_bc VARCHAR2(4);
    BEGIN
        BEGIN
            SELECT
                TRIM(bill_cyc_cd)
            INTO l_bc
            FROM
                ci_acct
            WHERE
                acct_id = p_acct_id;

        EXCEPTION
            WHEN no_data_found THEN
                NULL;
            WHEN OTHERS THEN
                log_error('BILL CYCLE ' || p_acct_id, sqlerrm, 'Error encountered at function GET_BILLING_CYCLE', NULL, NULL,
                         NULL, NULL);
        END;

        RETURN l_bc;
    END get_billing_cycle;

    PROCEDURE insert_adjustments (
        p_tran_no  IN NUMBER,
        p_bill_id  IN VARCHAR2,
        p_sa_id    IN VARCHAR2,
        p_cmdm_amt IN NUMBER
    )
    -- added by bcc on 02.07.2012
        -- this will enumerate all adjustments made
        -- to the electric SA that is sweeped by the bill
        -- note: all adjustment types must be inserted into bp_detail_codes
        --       and all SA types must be inserted into bp_detail_codes

        -- added by bcc on 06/01/2016
        -- included cancelled bills
     IS
        l_xfer_adj_id ci_adj.xfer_adj_id%TYPE;
        l_sa_type_cd  ci_sa.sa_type_cd%TYPE;
        l_cmdm_amt    NUMBER;
    BEGIN
        l_cmdm_amt := p_cmdm_amt;

        -- gather all billing cancellations
        -- swept by the bill
        FOR r IN (
            SELECT
                'BX'         adj_type_cd,
                SUM(cur_amt) adj_amt
            FROM
                ci_ft
            WHERE
                    sa_id = p_sa_id
                AND ft_type_flg IN ( 'BX' )
                AND bill_id = p_bill_id
            HAVING
                SUM(cur_amt) <> 0
        ) LOOP
            IF l_cmdm_amt <> 0 THEN
                add_detail_line(p_tran_no, r.adj_type_cd, NULL, r.adj_amt);
                l_cmdm_amt := l_cmdm_amt + ( r.adj_amt * -1 );
            END IF;
        END LOOP;

        -- gather all 2306 adjustments
        -- swept by the bill
        FOR r IN (
            SELECT
                '2306'       adj_type_cd,
                SUM(cur_amt) adj_amt
            FROM
                ci_ft
            WHERE
                    sa_id = p_sa_id
                AND bill_id = p_bill_id
                AND ft_type_flg IN ( 'AD', 'AX' )
                AND TRIM(parent_id) LIKE '2306%'
            HAVING
                SUM(cur_amt) <> 0
        ) LOOP
            IF l_cmdm_amt <> 0 THEN
                add_detail_line(p_tran_no, r.adj_type_cd, NULL, r.adj_amt);
                l_cmdm_amt := l_cmdm_amt + ( r.adj_amt * -1 );
            END IF;
        END LOOP;

        -- gather all adjustments that are not transfer adjustments
        -- swept by the bill
        -- excpt 2306
        FOR r IN (
            SELECT
                TRIM(parent_id) adj_type_cd,
                sibling_id      adj_id,
                SUM(cur_amt)    adj_amt
            FROM
                ci_ft
            WHERE
                    sa_id = p_sa_id
                AND bill_id = p_bill_id
                AND ft_type_flg IN ( 'AD', 'AX' )
                AND TRIM(parent_id) <> 'SURCHADJ'
                AND TRIM(parent_id) NOT LIKE '2306%'
            GROUP BY
                parent_id,
                sibling_id
            HAVING
                SUM(cur_amt) <> 0
        ) LOOP
            -- check if it is a transfer adjustment
            l_xfer_adj_id := '0';
            BEGIN
                SELECT
                    nvl(TRIM(xfer_adj_id), '0')
                INTO l_xfer_adj_id
                FROM
                    ci_adj a
                WHERE
                    adj_id = r.adj_id;

            EXCEPTION
                WHEN OTHERS THEN
                    l_xfer_adj_id := '0';
            END;

            -- if it is not a transfer adjustment
            -- insert the adjustment type into bp_details
            IF l_xfer_adj_id = '0' THEN
                IF l_cmdm_amt <> 0 THEN
                    add_detail_line(p_tran_no, r.adj_type_cd, NULL, r.adj_amt);
                    l_cmdm_amt := l_cmdm_amt + ( r.adj_amt * -1 );
                END IF;
            END IF;

        END LOOP;

        -- gather all  transfer adjustments
        -- swept by the bill
        -- excpt 2306
        FOR r IN (
            SELECT
                TRIM(parent_id) adj_type_cd,
                sibling_id      adj_id,
                SUM(cur_amt)    adj_amt
            FROM
                ci_ft
            WHERE
                    sa_id = p_sa_id
                AND bill_id = p_bill_id
                AND ft_type_flg IN ( 'AD', 'AX' )
                AND TRIM(parent_id) <> 'SURCHADJ'
                AND TRIM(parent_id) NOT LIKE '2306%'
            GROUP BY
                parent_id,
                sibling_id
            HAVING
                SUM(cur_amt) <> 0
        ) LOOP
            -- check if it is a transfer adjustment
            l_xfer_adj_id := '0';
            BEGIN
                SELECT
                    nvl(TRIM(xfer_adj_id), '0')
                INTO l_xfer_adj_id
                FROM
                    ci_adj a
                WHERE
                    adj_id = r.adj_id;

            EXCEPTION
                WHEN OTHERS THEN
                    l_xfer_adj_id := '0';
            END;

            -- if it is a transfer adjustment
            -- insert the adjustment type into bp_details
            IF l_xfer_adj_id <> '0' THEN
                -- retrieve the sa_type_cd of
                -- the sa_id in the adjustment
                BEGIN
                    SELECT
                        sa_type_cd
                    INTO l_sa_type_cd
                    FROM
                        ci_adj a,
                        ci_sa  sa
                    WHERE
                            sa.sa_id = a.sa_id
                        AND adj_id = l_xfer_adj_id;

                EXCEPTION
                    WHEN OTHERS THEN
                        raise_application_error(-20453, 'SA type cd does not exist. adj_id = ' || l_xfer_adj_id);
                END;

                IF
                    l_cmdm_amt <> 0
                    AND r.adj_amt <> 0
                THEN
                    add_detail_line(p_tran_no, trim(l_sa_type_cd), NULL, r.adj_amt);
                    l_cmdm_amt := l_cmdm_amt + ( r.adj_amt * -1 );
                END IF;

            END IF;

        END LOOP;

        -- gather all adjustments from other SAs
        -- swept by the bill
        -- excpt 2306
        FOR r IN (
            SELECT
                TRIM(parent_id) adj_type_cd,
                sibling_id      adj_id,
                SUM(cur_amt)    adj_amt
            FROM
                ci_ft      ft,
                ci_sa      sa,
                ci_sa_type sat
            WHERE
                    ft.sa_id = sa.sa_id
                AND sa.sa_type_cd = sat.sa_type_cd
                AND svc_type_cd = 'EL'
                AND ft.sa_id <> p_sa_id
                AND ft.bill_id = p_bill_id
                AND ft.ft_type_flg IN ( 'AD', 'AX' )
                AND TRIM(ft.parent_id) <> 'SURCHADJ'
                AND TRIM(ft.parent_id) NOT LIKE '2306%'
            GROUP BY
                ft.parent_id,
                ft.sibling_id
            HAVING
                SUM(ft.cur_amt) <> 0
        ) LOOP
            -- insert the adjustment type into bp_details
            IF l_cmdm_amt <> 0 THEN
                add_detail_line(p_tran_no, r.adj_type_cd, NULL, r.adj_amt);
                l_cmdm_amt := l_cmdm_amt + ( r.adj_amt * -1 );
            END IF;
        END LOOP;

    END;

    PROCEDURE retrieve_flt_info (
        p_acct_no       IN VARCHAR2,
        p_bill_month    IN DATE,
        p_qty           IN OUT NUMBER,
        p_total_wattage IN OUT NUMBER
    ) AS
    BEGIN
        BEGIN
            --final sql
            SELECT
                qty,
                total_wattage
            INTO
                p_qty,
                p_total_wattage
            FROM
                synergen.cm_vw_unmetered_summary@wam.davaolight.com
            WHERE
                    to_char(month_date, 'YYYYMM') = to_char(add_months(p_bill_month, - 1), 'YYYYMM')
                AND account_no = p_acct_no;
            --          WHERE       account_no = p_acct_no
            --                  AND month_date >= p_bill_month
            --                  AND month_date < LAST_DAY (p_bill_month) + 1
            --                  AND ROWNUM = 1;

            --temporarily enabled for testing
            /*SELECT   qty, total_wattage
             INTO   p_qty, p_total_wattage
             FROM   cm_flatrate_summary_vw
            WHERE       account_no = p_acct_no
                    AND month_date >= p_bill_month
                    AND month_date < LAST_DAY (p_bill_month) + 1
                    AND ROWNUM = 1;*/
        EXCEPTION
            WHEN OTHERS THEN
                log_error('CM_FLATRATE_SUMMARY_VW ' || p_acct_no, sqlerrm, to_char(p_bill_month, 'MM/DD/YYYY'), NULL, NULL, NULL, NULL);
        END;
    END;

    FUNCTION get_bpx_reg_entry (
        p_reg_code IN VARCHAR2,
        p_as_of    IN DATE DEFAULT sysdate
    ) RETURN VARCHAR2 IS

        CURSOR bpx_reg IS
        SELECT
            value
        FROM
            bpx_registry
        WHERE
                reg_code = p_reg_code
            AND effective_on <= p_as_of
        ORDER BY
            effective_on DESC;

        l_value bpx_registry.value%TYPE;
    BEGIN
        OPEN bpx_reg;
        FETCH bpx_reg INTO l_value;
        CLOSE bpx_reg;
        RETURN ( l_value );
    END get_bpx_reg_entry;

    PROCEDURE populate_bill_msg_param (
        p_tran_no IN NUMBER,
        p_bill_id IN VARCHAR2
    ) AS
        l_errmsg  VARCHAR2(3000);
        l_errline NUMBER;
    BEGIN
        l_errline := 10;
        INSERT INTO bp_message_param
            SELECT
                p_tran_no         tran_no,
                TRIM(bill_msg_cd) bill_msg_cd,
                seq_num,
                msg_parm_val
            FROM
                ci_bill_msg_prm
            WHERE
                bill_id = p_bill_id;

    EXCEPTION
        WHEN OTHERS THEN
            l_errmsg := 'Error @ function POPULATE_BILL_MSG_PARAM - ' || sqlerrm;
            log_error('p_bill_no: ' || p_bill_id, l_errmsg, NULL, NULL, NULL,
                     NULL);
            ROLLBACK;
            raise_application_error(-20201, l_errmsg);
    END populate_bill_msg_param;

    PROCEDURE extract_bills (
        p_batch_cd  IN VARCHAR2,
        p_batch_nbr IN NUMBER,
        p_du_set_id IN NUMBER,
        p_thread_no IN NUMBER DEFAULT 1,
        p_first_row IN NUMBER DEFAULT NULL,
        p_last_row  IN NUMBER DEFAULT NULL,
        p_bill_id   IN VARCHAR2 DEFAULT NULL
    ) IS

        CURSOR bill_routes_cur IS
        SELECT
            *
        FROM
            (
                SELECT
                    DENSE_RANK()
                    OVER(
                        ORDER BY
                            br.rowid
                    )                                              row_number,
                    br.batch_cd,
                    br.batch_nbr,
                    br.bill_id,
                    br.entity_name1                                customer_name,
                    br.address1,
                    br.address2,
                    br.address3
                    || ' '
                    || br.address4                                 address3,
                    br.city,
                    TRIM(b.bill_cyc_cd)                            billing_batch_no,
                    trunc(nvl(b.win_start_dt, b.bill_dt), 'MONTH') bill_month,
                    b.bill_dt,
                    b.due_dt,
                    TRIM(bchar.char_val)                           bill_color,
                           -- decode(substr(br.batch_cd, -1), 'G', 'GREEN', 'RED') bill_color,
                    b.acct_id                                      acct_no,
                    b.complete_dttm,
                    br.no_batch_prt_sw
                FROM
                    ci_bill_routing br,
                    ci_bill         b,
                    ci_bill_char    bchar
                WHERE
                        br.bill_id = b.bill_id
                    AND b.bill_id = bchar.bill_id
                    AND b.bill_stat_flg = 'C'
                    AND br.bill_rte_type_cd IN ( 'POSTAL', 'POSTAL2' )
                    AND bchar.char_type_cd = 'BILLIND '
                    AND bchar.seq_num = 1 --only the first entry in the bill characteristics
                    AND br.seqno = 1 -- just get the first entry in the bill routing
                    AND br.batch_cd = rpad(p_batch_cd, 8)
                    AND br.batch_nbr = p_batch_nbr
                    AND b.bill_id = nvl(p_bill_id, b.bill_id)
                          --and    b.bill_id          <> '591307558001' -- not to extract this bill id (dummy billing) -->> v1.0.7 - not applicable to DLPC
                    AND NOT EXISTS (
                        SELECT
                            NULL
                        FROM
                            bp_headers
                        WHERE
                            bill_no = b.bill_id
                    )
            )
        WHERE
                row_number >= nvl(p_first_row, 1)
            AND row_number <= nvl(p_last_row, 1000000000);

        TYPE br_tab_type IS
            TABLE OF bill_routes_cur%rowtype INDEX BY BINARY_INTEGER;
        l_br                br_tab_type;
        l_row               PLS_INTEGER;
        l_du_set_id         NUMBER;
        l_total_recs        NUMBER;
        l_curr_rec          NUMBER := 0;
        l_bph               bp_headers%rowtype;
        l_main_sa_id        ci_sa.sa_id%TYPE;
        l_main_sa_dt        DATE;
        l_main_prem_id      ci_sa.char_prem_id%TYPE;
        l_bill_amt          bp_headers.bill_amt%TYPE;
        l_estimate_note     VARCHAR2(20);
        l_other_bseg_amt    NUMBER;
        l_cmdm_amt          NUMBER;
        l_start_dttm        DATE;
        l_end_dttm          DATE;
        l_tran_no           bp_headers.tran_no%TYPE;
        l_ebill_only_sw     CHAR(1);
        l_2014_recovery_adj NUMBER;
        l_adj_space         NUMBER;
        l_txt_only          VARCHAR2(1);
        l_bd_amt            NUMBER; --02/29/2024
    BEGIN
        --dbms_output.put_line ('inside extract_bills');

        -- if requeset is to extract a specific bill_id
        -- check first in the archive tables
        -- if the bill is there, get it from there
        IF p_bill_id IS NOT NULL THEN
            --            begin
            --                select tran_no
            --                into   l_tran_no
            --                from   bp_headers_arc
            --                where  bill_no = p_bill_id;
            --            exception
            --                when no_data_found
            --                then
            --                    l_tran_no := null;
            --            end;

            l_tran_no := NULL;
            IF l_tran_no IS NOT NULL THEN
                BEGIN
                    INSERT INTO bp_headers
                        ( SELECT
                            *
                        FROM
                            bp_headers_arc
                        WHERE
                            tran_no = l_tran_no
                        );

                EXCEPTION
                    WHEN OTHERS THEN
                        log_error('Single Bill Extraction', sqlerrm, 'Inserting to bp_headers');
                END;

                BEGIN
                    INSERT INTO bp_details
                        ( SELECT
                            *
                        FROM
                            bp_details_arc
                        WHERE
                            tran_no = l_tran_no
                        );

                EXCEPTION
                    WHEN OTHERS THEN
                        log_error('Single Bill Extraction', sqlerrm, 'Inserting to bp_details');
                END;

                BEGIN
                    INSERT INTO bp_meter_details
                        ( SELECT
                            *
                        FROM
                            bp_meter_details_arc
                        WHERE
                            tran_no = l_tran_no
                        );

                EXCEPTION
                    WHEN OTHERS THEN
                        log_error('Single Bill Extraction', sqlerrm, 'Inserting to bp_meter_details');
                END;

                BEGIN
                    INSERT INTO bp_consumption_hist
                        ( SELECT
                            *
                        FROM
                            bp_consumption_hist_arc
                        WHERE
                            tran_no = l_tran_no
                        );

                EXCEPTION
                    WHEN OTHERS THEN
                        log_error('Single Bill Extraction', sqlerrm, 'Inserting to bp_consumption_hist');
                END;

                COMMIT;
                RETURN;
            END IF;

        END IF;

        -- update the batch control
        -- increment the batch number so that the next extract will be
        -- grouped under a new batch number
        BEGIN
            IF p_bill_id IS NULL THEN
                UPDATE ci_batch_ctrl
                SET
                    next_batch_nbr = next_batch_nbr + 1
                WHERE
                        batch_cd = rpad(p_batch_cd, 8)
                    AND next_batch_nbr = p_batch_nbr;

            END IF;

            -- commit right away, so other threads will not be waiting for the
            -- lock on the record to be released
            COMMIT;
        EXCEPTION
            WHEN OTHERS THEN
                log_error('Updating Batch Control', sqlerrm, NULL, 'CI_BATCH_CTRL', p_batch_cd,
                         p_batch_nbr, p_thread_no);
                raise_application_error(-20002, sqlerrm);
        END;

        l_start_dttm := sysdate;
        dbms_application_info.set_module('BPX:' || to_char(l_start_dttm, 'hh24:mi:ss'), 'Extracting Bills');
        dbms_application_info.set_client_info('TRD-'
                                              || to_char(p_thread_no, 'fm00')
                                              || ': Initializing please wait...');

        -- count total rows to process
        IF p_bill_id IS NOT NULL THEN
            l_total_recs := 1;
        ELSIF
            p_first_row IS NOT NULL
            AND p_last_row IS NOT NULL
        THEN
            l_total_recs := ( p_last_row - p_first_row ) + 1;
        ELSE
            l_total_recs := get_extract_bill_count(p_batch_cd, p_batch_nbr);
        END IF;

        dbms_application_info.set_client_info('TRD-'
                                              || to_char(p_thread_no, 'fm00')
                                              || ': Total Records - '
                                              || to_char(l_total_recs, 'fm999,999,999'));

        --dbms_output.put_line ('before bill_routes_cur');
        OPEN bill_routes_cur;
        LOOP
            FETCH bill_routes_cur
            BULK COLLECT INTO l_br LIMIT 1000;
            l_row := l_br.first;
            WHILE ( l_row IS NOT NULL ) LOOP
                --dbms_output.put_line ('after bill_routes_cur');
                -- intialize bp_header record
                l_bph := NULL;
                l_curr_rec := l_curr_rec + 1;
                dbms_application_info.set_client_info('TRD-'
                                                      || to_char(p_thread_no, 'fm00')
                                                      || ': '
                                                      || to_char(l_curr_rec)
                                                      || '/'
                                                      || to_char(l_total_recs)
                                                      || ' '
                                                      || to_char(ceil((l_curr_rec / l_total_recs) * 100))
                                                      || '% ');

                l_main_sa_id := NULL;
                l_main_sa_dt := TO_DATE('01011900', 'mmddyyyy');
                l_main_prem_id := NULL;
                l_estimate_note := NULL;
                l_bph.overdue_amt := NULL;
                l_bph.overdue_bill_count := NULL;
                l_bph.bill_amt := NULL;

                --dbms_output.put_line ('before r2 loop');
                FOR r2 IN (
                    SELECT
                        sa.sa_id,
                        TRIM(st.dst_id)           dst_id,
                        TRIM(st.bill_seg_type_cd) bill_seg_type_cd,
                        bs.end_dt,
                        bs.est_sw,
                        sa.char_prem_id,
                        sa.sa_status_flg
                    FROM
                        ci_bseg    bs,
                        ci_sa      sa,
                        ci_sa_type st
                    WHERE
                            bs.sa_id = sa.sa_id
                        AND st.sa_type_cd = sa.sa_type_cd
                        AND bs.bseg_stat_flg IN ( '50', '70' ) -- Frozen/OK
                        AND bs.bill_id = l_br(l_row).bill_id
                        AND TRIM(st.dst_id) = 'AR-ELC' -->> v1.0.7 - change DIST_ID from 'A/R-ELEC' to 'AR-ELC'
                        AND TRIM(st.bill_seg_type_cd) IN ( 'SP-RATED', 'NOSP-RAT', 'BD-RATED' )
                        AND sa.sa_type_cd != 'NET-E'
                ) LOOP
                    --dbms_output.put_line ('inside r2 loop');
                    IF r2.end_dt > l_main_sa_dt THEN
                        l_main_sa_dt := r2.end_dt;
                        l_main_sa_id := r2.sa_id;
                        l_main_prem_id := r2.char_prem_id;

                        /*if l_br(l_row).bill_month is null
                        then
                           l_br(l_row).bill_month := trunc(r2.end_dt, 'MONTH');
                        end if;*/

                        l_br(l_row).bill_month := trunc(r2.end_dt, 'MONTH');

                        -- determine if bill is estimated
                        IF r2.est_sw = 'Y' THEN
                            l_bph.bill_type := 'E'; -- estimated
                            l_estimate_note := '(ESTIMATE)';
                        ELSE
                            l_bph.bill_type := 'R'; -- regular
                        END IF;

                        -- determin if last billing
                        IF TRIM(r2.sa_status_flg) IN ( '30', '40' ) THEN
                            l_bph.last_bill_flg := 'Y';
                        ELSE
                            l_bph.last_bill_flg := 'N';
                        END IF;

                        l_bill_amt := get_current_bill_amt(l_br(l_row).bill_id, r2.sa_id);

                        -- get current bill amount
                        l_bph.bill_amt := nvl(l_bph.bill_amt, 0) + l_bill_amt;
                        l_bph.overdue_amt := 0;

                        --if l_br(l_row).bill_color = 'RED'
                        --then
                        -- get over due amount
                        l_bph.overdue_amt := nvl(l_bph.overdue_amt, 0) + get_overdue_amt90(l_br(l_row).bill_id);

                        IF l_bph.overdue_amt <= 0 THEN
                            l_br(l_row).bill_color := 'GREEN';
                        ELSE
                            --l_bph.overdue_bill_count := 1;
                            l_bph.overdue_bill_count := get_overdue_bill_cnt(r2.sa_id, l_br(l_row).bill_dt, l_bph.overdue_amt);
                        END IF;

                        --end if;

                        l_bph.par_kwhr := get_par_kwh(l_br(l_row).bill_id);
                        l_bph.par_month := get_par_month(r2.sa_id, r2.end_dt);
                    END IF;
                END LOOP;

                -- if there is  a billed Electric SA, dont proceed
                --dbms_output.put_line ('Bill amount condition');
                IF l_bph.bill_amt IS NOT NULL THEN
                    -- *** This section gets the bill's pertinent info ***
                    -- *** or the "not so critical" data

                    -- get crc
                    l_bph.crc := get_crc(l_br(l_row).acct_no);

                    -- get business style
                    l_bph.bus_activity := get_business_style(l_main_sa_id);

                    -- retrieve business address
                    retrieve_business_address(l_br(l_row).acct_no, l_bph.bus_add1, l_bph.bus_add2, l_bph.bus_add3, l_bph.bus_add4,
                                             l_bph.bus_add5);

                    -- retrieve bill address

                    l_bph.billing_add1 := l_br(l_row).address1;
                    l_bph.billing_add2 := l_br(l_row).address2;
                    l_bph.billing_add3 := l_br(l_row).address3;
                    retrieve_billing_address(l_br(l_row).acct_no, l_bph.billing_add1, l_bph.billing_add2, l_bph.billing_add3);

                    -- retrieve the premise address
                    retrieve_premise_address(l_main_prem_id, l_bph.premise_add1, l_bph.premise_add2, l_bph.premise_add3);

                    -- get the rate schedule of the account being billed
                    retrieve_rate_schedule(l_br(l_row).bill_id, l_main_sa_id, l_bph.rate_schedule, l_bph.rate_schedule_desc);

                    -- get default courier code based on the rate schedule
                    l_bph.courier_code := get_default_courier(l_bph.rate_schedule, l_br(l_row).billing_batch_no);

                    -- get area code, derived from bill routing city
                    l_bph.area_code := get_area_code(l_br(l_row).city);

                    -- get the last payment event, date and amount
                    --retrieve_last_payment(l_br(l_row).acct_no, l_br(l_row).bill_dt, l_bph.last_payment_date, l_bph.last_payment_amount);
                    retrieve_last_payment(l_br(l_row).acct_no, l_br(l_row).bill_id, l_br(l_row).bill_dt, l_bph.last_payment_date, l_bph.
                    last_payment_amount);

                    -- get book no. or service route
                    l_bph.book_no := get_book_no(l_main_sa_id);

                    -- get delivery sequence
                    BEGIN
                        l_bph.new_seq_no := get_bdseq(l_br(l_row).acct_no);
                    EXCEPTION
                        WHEN value_error THEN
                            l_bph.new_seq_no := 0;
                    END;


                    -- get tin
                    l_bph.tin := get_tin(l_br(l_row).acct_no);

                    -- get messenger code
                    l_bph.messenger_code := get_bdmsgr(l_br(l_row).acct_no);

                    -- get bill message
                    l_bph.message_code := get_bill_message(l_br(l_row).bill_id);

                    -- set default message code if message code is null
                    IF l_bph.message_code IS NULL THEN
                        l_bph.message_code := get_bpx_reg_entry('DEF_MSG_CD', sysdate);
                    END IF;

                    -- *** This section retrieves the "critical info" of the bill

                    -- get billed consumptions from bseg_sq
                    l_bph.billed_kwhr_cons := get_bill_sq(l_br(l_row).bill_id, l_main_sa_id, 'BILLKWH');

                    l_bph.billed_kvar_cons := get_bill_sq(l_br(l_row).bill_id, l_main_sa_id, 'BILLKVAR');

                    l_bph.billed_demand_cons := get_bill_sq(l_br(l_row).bill_id, l_main_sa_id, 'BILLKW');

                    l_bph.power_factor_value := get_bill_sq(l_br(l_row).bill_id, l_main_sa_id, 'BILLPF');

                    -- get net bill amount
                    l_bph.total_amt_due := get_net_bill_amt2(l_br(l_row).bill_id);
                    

                    -- get CAS bill no
                    l_bph.alt_bill_id := get_cas_bill_no(l_br(l_row).bill_id);

                    -- get location code
                    l_bph.location_code := get_location_code(l_br(l_row).acct_no);

                    -- get billing cycle
                    l_bph.billing_batch_no := l_br(l_row).billing_batch_no;
                    IF TRIM(l_bph.billing_batch_no) IS NULL THEN
                        l_bph.billing_batch_no := get_billing_cycle(l_br(l_row).acct_no);
                    END IF;

                    IF l_bph.billing_batch_no LIKE 'BU%' THEN
                        -- get kwhr billed consumption for flat rate bills
                        l_bph.billed_kwhr_cons := get_bill_sq(l_br(l_row).bill_id, l_main_sa_id, 'FLTKWH');

                        -- retrieve flatrate info such as number of connections   wattage
                        retrieve_flt_info(l_br(l_row).acct_no, l_br(l_row).bill_month, l_bph.flt_connection, l_bph.flt_wattage);

                    END IF;

                    l_bph.no_batch_prt_sw := l_br(l_row).no_batch_prt_sw;

                    -- tag for_ebill_account
                    BEGIN
                        l_ebill_only_sw := 'N';
                        SELECT
                            'Y'
                        INTO l_ebill_only_sw
                        FROM
                            ebill_accounts
                        WHERE
                                acct_id = l_br(l_row).acct_no
                            AND incld_in_batch_pr_sw = 'N'
                            AND enabled = 1;

                    EXCEPTION
                        WHEN no_data_found THEN
                            l_ebill_only_sw := 'N';
                        WHEN too_many_rows THEN
                            l_ebill_only_sw := 'Y';
                    END;

                    -- get tag for ebill_txt_account
                    l_txt_only := get_text_only_tag(l_br(l_row).acct_no); -->> v1.3.9

                    -- now create the header record for the bill
                    BEGIN
                        INSERT INTO bp_headers (
                            du_set_id,
                            batch_cd,
                            batch_no,
                            bill_no,
                            customer_name,
                            premise_add1,
                            premise_add2,
                            premise_add3,
                            billing_add1,
                            billing_add2,
                            billing_add3,
                            billing_batch_no,
                            bill_date,
                            due_date,
                            bill_month,
                            acct_no,
                            crc,
                            bill_color,
                            rate_schedule,
                            rate_schedule_desc,
                            courier_code,
                            last_payment_date,
                            last_payment_amount,
                            area_code,
                            book_no,
                            old_seq_no,
                            new_seq_no,
                            bill_amt,
                            total_amt_due,
                            overdue_amt,
                            overdue_bill_count,
                            message_code,
                            billed_kwhr_cons,
                            billed_kvar_cons,
                            billed_demand_cons,
                            power_factor_value,
                            main_sa_id,
                            bill_type,
                            alt_bill_id,
                            messenger_code,
                            last_bill_flg,
                            location_code,
                            par_kwhr,
                            par_month,
                            complete_date,
                            flt_connection,
                            flt_wattage,
                            no_batch_prt_sw,
                            ebill_only_sw,
                            tin,
                            bus_activity,
                            bus_add1,
                            bus_add2,
                            bus_add3,
                            bus_add4,
                            bus_add5,
                            txt_only
                        ) VALUES (
                            p_du_set_id,
                            l_br(l_row).batch_cd,
                            l_br(l_row).batch_nbr,
                            l_br(l_row).bill_id,
                            l_br(l_row).customer_name,
                            l_bph.premise_add1,
                            l_bph.premise_add2,
                            l_bph.premise_add3,
                            l_bph.billing_add1,
                            l_bph.billing_add2,
                            l_bph.billing_add3,
                            l_bph.billing_batch_no,
                            l_br(l_row).bill_dt,
                            l_br(l_row).due_dt,
                            l_br(l_row).bill_month,
                            l_br(l_row).acct_no,
                            l_bph.crc,
                            l_br(l_row).bill_color,
                            l_bph.rate_schedule,
                            l_bph.rate_schedule_desc,
                            l_bph.courier_code,
                            l_bph.last_payment_date,
                            l_bph.last_payment_amount,
                            l_bph.area_code,
                            l_bph.book_no,
                            0,
                            l_bph.new_seq_no,
                            l_bph.bill_amt,
                            l_bph.total_amt_due,
                            l_bph.overdue_amt,
                            l_bph.overdue_bill_count,
                            l_bph.message_code,
                            l_bph.billed_kwhr_cons,
                            l_bph.billed_kvar_cons,
                            l_bph.billed_demand_cons,
                            l_bph.power_factor_value,
                            l_main_sa_id,
                            l_bph.bill_type,
                            l_bph.alt_bill_id,
                            l_bph.messenger_code,
                            l_bph.last_bill_flg,
                            l_bph.location_code,
                            l_bph.par_kwhr,
                            l_bph.par_month,
                            l_br(l_row).complete_dttm,
                            l_bph.flt_connection,
                            l_bph.flt_wattage,
                            l_bph.no_batch_prt_sw,
                            l_ebill_only_sw,
                            l_bph.tin,
                            l_bph.bus_activity,
                            l_bph.bus_add1,
                            l_bph.bus_add2,
                            l_bph.bus_add3,
                            l_bph.bus_add4,
                            l_bph.bus_add5,
                            l_txt_only
                        ) RETURNING tran_no INTO l_bph.tran_no;

                    EXCEPTION
                        WHEN dup_val_on_index THEN
                            log_error('Insert to headers', sqlerrm, 'Duplicate Bill ID', 'BP_HEADERS', p_batch_cd,
                                     p_batch_nbr, l_br(l_row).bill_id);
                            -- raise_application_error(-20202, sqlerrm);

                        WHEN OTHERS THEN
                            log_error('Insert to headers', sqlerrm, NULL, 'BP_HEADERS', p_batch_cd,
                                     p_batch_nbr, l_br(l_row).bill_id);

                            dbms_application_info.set_action('Error Encountered.');
                            raise_application_error(-20201, sqlerrm);
                    END;
                    
                    

                    IF l_bph.tran_no IS NOT NULL THEN
                        -- insert bill message parameters
                        populate_bill_msg_param(l_bph.tran_no, l_br(l_row).bill_id);

                        -- insert meter details
                        dbms_output.put_line('MDM Search');
                        cm_bp_extract_util_pkg.insert_meter_details(l_bph.tran_no, l_br(l_row).bill_id, l_main_sa_id, l_br(l_row).bill_dt);

                        -- insert consumption history
                        insert_consumption_hist(l_bph.tran_no, l_br(l_row).acct_no, l_br(l_row).bill_dt);

                        -- insert consumption history for flatrate bills
                        IF l_bph.billing_batch_no LIKE 'BU%' THEN
                            insert_flt_consumption_hist(l_bph.tran_no, l_br(l_row).acct_no, l_br(l_row).bill_dt);
                        END IF;

                        -- insert the bill's detail lines
                        insert_bp_details(l_bph.tran_no, l_br(l_row).bill_id, l_br(l_row).bill_dt, l_main_sa_id);
                        -- insert bir 2013 requirements
                        populate_bp_bir_2013(l_bph.tran_no, l_br(l_row).bill_id);

                        -- insert additional info for the bill's detail lines
                        add_detail_line(l_bph.tran_no, 'OVERDUE', NULL, l_bph.overdue_amt);
                        add_detail_line(l_bph.tran_no, 'CURBIL', to_char(l_br(l_row).bill_month, 'fmMONTH YYYY')
                                                                 || l_estimate_note, l_bph.bill_amt);
                                                                 
                       /* -- insert bill deposit to bp_details                                         
                        l_bd_amt := bp_extract_pkg.get_bd_bseg_amt(p_bill_no => l_br(l_row).bill_id); --02/29/2024
                        add_detail_line(l_bph.tran_no, 'BDSA', NULL, l_bd_amt);*/

                        --add_detail_line (
                        --l_bph.tran_no,
                        --'OUTAMT',
                        --null,
                        --l_bph.total_amt_due
                        --);

                        IF l_br(l_row).bill_color = 'GREEN' THEN
                            add_detail_line(l_bph.tran_no, 'GREEN_OUTAMT', NULL, l_bph.total_amt_due);
                            add_detail_line(l_bph.tran_no, 'CCBNOTICE', to_char(l_br(l_row).due_dt, 'MM/DD/YYYY'), NULL);

                        ELSE
                            add_detail_line(l_bph.tran_no, 'RED_OUTAMT', NULL, l_bph.total_amt_due);
                            add_detail_line(l_bph.tran_no, 'CCBREDNOTICE', NULL, NULL);
                        END IF;
                        
                   

                        -- add info on last payment date and amount
                        IF l_bph.last_payment_date IS NOT NULL THEN
                            add_detail_line(l_bph.tran_no, 'CCBNOTICE1', 'LAST PAYMENT  -  '
                                                                         || to_char(l_bph.last_payment_date, 'fmMONTH DD, YYYY')
                                                                         || '  -  '
                                                                         || to_char(l_bph.last_payment_amount, 'fm9,999,999,990.00'),
                                                                         NULL);
                        END IF;

                        l_other_bseg_amt := 0;

                        -- insert Payment Arrangements and such
                        IF l_bph.total_amt_due <> l_bph.bill_amt + l_bph.overdue_amt THEN
                            insert_other_bseg2(l_bph.tran_no, l_br(l_row).bill_id);
                            l_other_bseg_amt := get_other_bseg_amt2(l_br(l_row).bill_id);
                        END IF;
                        
                        --insert BD bseg amt
                        if l_bph.total_amt_due <> l_bph.bill_amt + l_bph.overdue_amt THEN
                           
                           insert_bd_bseg(l_bph.tran_no, l_br(l_row).bill_id);
                           l_other_bseg_amt := get_bd_bseg_amt(l_br(l_row).bill_id);
                          
                        end if;

                        -- insert cmdm amount
                        l_cmdm_amt := l_bph.total_amt_due - ( l_bph.bill_amt + l_other_bseg_amt + l_bph.overdue_amt );

                        IF l_cmdm_amt <> 0 THEN
                            insert_adjustments(l_bph.tran_no, l_br(l_row).bill_id, l_main_sa_id, l_cmdm_amt);
                            IF l_other_bseg_amt <> 0 THEN
                                adjust_pa_arrears(l_bph.tran_no, l_br(l_row).bill_id);
                            END IF;

                        END IF;

                        IF ( bp_registry_pkg.get_value_asof('ECQ_ON') = 'Y' ) THEN
                            add_ecq_info(l_bph.tran_no, l_br(l_row).bill_id, l_bph.total_amt_due);
                        END IF;
                        
                        

                        IF l_cmdm_amt <> 0 THEN
                            adjust_dr_cr_line(l_bph.tran_no, l_br(l_row).bill_id, l_main_sa_id);
                        END IF;

                    END IF;
                    
                    

                    --adjust_recovery_adj_2014(l_br(l_row).bill_id,l_main_sa_id,l_bph.tran_no,l_2014_recovery_adj);
                    IF ( l_2014_recovery_adj != 0 ) THEN
                        l_bph.bill_amt := l_bph.bill_amt - l_2014_recovery_adj;
                        UPDATE bp_headers
                        SET
                            bill_amt = l_bph.bill_amt + l_2014_recovery_adj
                        WHERE
                            tran_no = l_bph.tran_no;

                        UPDATE bp_details
                        SET
                            line_amount = l_bph.bill_amt + l_2014_recovery_adj
                        WHERE
                                tran_no = l_bph.tran_no
                            AND line_code = 'CURBIL';

                        l_adj_space := 1;
                    END IF;

                    IF l_adj_space = 1 THEN
                        add_detail_line(l_bph.tran_no, 'ADJ_SPACE', NULL, NULL);
                    END IF;
                    
                    

                    --remove_zero_line_amt
                    remove_zero_line_amt(l_bph.tran_no); --gperater 08/18/2023

                    --sum-up the adjustment for PBR Guaranteed Service Level
                    summarize_gsl(l_br(l_row).bill_id);
                END IF;

                l_row := l_br.next(l_row);
            END LOOP;

            EXIT WHEN bill_routes_cur%notfound;
        END LOOP; -- driving loop;

        CLOSE bill_routes_cur;
        COMMIT;
        l_end_dttm := sysdate;
        dbms_application_info.set_action(to_char(l_end_dttm, 'hh24:mi:ss'));
        dbms_application_info.set_client_info('TRD-'
                                              || to_char(p_thread_no, 'fm00')
                                              || ': Done in '
                                              || to_char(round((l_end_dttm - l_start_dttm) * 1440, 2), 'fm999,990.00')
                                              || ' mins.');

    END;

    PROCEDURE extract_multi_threaded (
        p_batch_cd     IN VARCHAR2,
        p_batch_nbr    IN NUMBER,
        p_thread_count IN NUMBER
    ) IS
        l_du_set_id       NUMBER;
        l_total_recs      NUMBER;
        l_recs_per_thread NUMBER;
    BEGIN
        BEGIN
            SELECT
                bph_du_set_ids.NEXTVAL
            INTO l_du_set_id
            FROM
                dual;

        EXCEPTION
            WHEN OTHERS THEN
                raise_application_error(-20001, sqlerrm);
        END;

        BEGIN
            SELECT
                COUNT(*)
            INTO l_total_recs
            FROM
                ci_bill_routing br,
                ci_bill         b
            WHERE
                    br.bill_id = b.bill_id
                AND br.batch_cd = rpad(p_batch_cd, 8)
                AND br.batch_nbr = p_batch_nbr
                AND b.bill_stat_flg = 'C'
                AND NOT EXISTS (
                    SELECT
                        NULL
                    FROM
                        bp_headers
                    WHERE
                        bill_no = b.bill_id
                );

        END;

        IF l_total_recs > 0 THEN
            l_recs_per_thread := ceil(l_total_recs / p_thread_count);
            FOR r IN 0..p_thread_count - 1 LOOP
                dbms_job.isubmit(901 + r, 'bp_extract_pkg.extract_bills('''
                                          || p_batch_cd
                                          || ''','
                                          || to_char(p_batch_nbr)
                                          || ','
                                          || to_char(l_du_set_id)
                                          || ','
                                          || to_char(r + 1)
                                          || ','
                                          || to_char((r * l_recs_per_thread) + 1)
                                          || ','
                                          || to_char((r * l_recs_per_thread) + l_recs_per_thread)
                                          || ');', sysdate);

                COMMIT;
            END LOOP;

        END IF;

    END;

    PROCEDURE archive_bills IS
        l_tran_no bp_headers.tran_no%TYPE;
    BEGIN
        log_error('Archiving bills', NULL, 'Started.');
        BEGIN
            DELETE FROM bp_headers bph
            WHERE
                EXISTS (
                    SELECT
                        NULL
                    FROM
                        bp_headers_arc bpha
                    WHERE
                        bpha.bill_no = bph.bill_no
                );

        EXCEPTION
            WHEN OTHERS THEN
                log_error('Archiving bills', sqlerrm, 'Deleting duplicates');
                raise_application_error(-20001, sqlerrm);
        END;

        COMMIT;
        BEGIN
            INSERT /*+append*/ INTO bp_headers_arc
                ( SELECT
                    *
                FROM
                    bp_headers
                );

        EXCEPTION
            WHEN OTHERS THEN
                log_error('Archiving bills', sqlerrm, 'Inserting to bp_headers_arc');
                raise_application_error(-20002, sqlerrm);
        END;

        COMMIT;
        BEGIN
            INSERT /*+append*/ INTO bp_details_arc
                ( SELECT
                    *
                FROM
                    bp_details
                );

        EXCEPTION
            WHEN OTHERS THEN
                log_error('Archiving bills', sqlerrm, 'Inserting to bp_details_arc');
                raise_application_error(-20003, sqlerrm);
        END;

        COMMIT;
        BEGIN
            INSERT /*+append*/ INTO bp_meter_details_arc
                ( SELECT
                    *
                FROM
                    bp_meter_details
                );

        EXCEPTION
            WHEN OTHERS THEN
                log_error('Archiving bills', sqlerrm, 'Inserting to bp_meter_details_arc');
                raise_application_error(-20004, sqlerrm);
        END;

        COMMIT;
        BEGIN
            INSERT /*+append*/ INTO bp_consumption_hist_arc
                ( SELECT
                    *
                FROM
                    bp_consumption_hist
                );

        EXCEPTION
            WHEN OTHERS THEN
                log_error('Archiving bills', sqlerrm, 'Inserting to bp_consumption_hist_arc');
                raise_application_error(-20005, sqlerrm);
        END;

        COMMIT;
        EXECUTE IMMEDIATE 'truncate table bp_details';
        EXECUTE IMMEDIATE 'truncate table bp_meter_details';
        EXECUTE IMMEDIATE 'truncate table bp_consumption_hist';
        EXECUTE IMMEDIATE 'alter table bp_details modify constraint BPD_BPH_FK2 disable';
        EXECUTE IMMEDIATE 'alter table bp_meter_details modify constraint BMD_BPH_FK2 disable';
        EXECUTE IMMEDIATE 'alter table bp_consumption_hist modify constraint BCH_BPH_FK2 disable';
        EXECUTE IMMEDIATE 'truncate table bp_headers';
        EXECUTE IMMEDIATE 'alter table bp_details modify constraint BPD_BPH_FK2 enable';
        EXECUTE IMMEDIATE 'alter table bp_meter_details modify constraint BMD_BPH_FK2 enable';
        EXECUTE IMMEDIATE 'alter table bp_consumption_hist modify constraint BCH_BPH_FK2 enable';
        log_error('Archiving bills', NULL, 'Completed.');
    END;

    PROCEDURE adjust_recovery_adj_2014 (
        p_bill_id           IN VARCHAR2,
        p_sa_id             IN VARCHAR2,
        p_tran_no           IN NUMBER,
        p_2014_recovery_adj OUT NUMBER
    ) AS
        l_gen_trans_adj        NUMBER;
        l_sysloss_lifeline_adj NUMBER;
        l_inter_class_sub_adj  NUMBER;
        l_2014_adj             NUMBER;
    BEGIN
        l_inter_class_sub_adj := 0;

        --Recovery for Systems Loss and Lifeline Subsidy
        BEGIN
            SELECT
                SUM(nvl(line_amount, 0))
            INTO l_inter_class_sub_adj
            FROM
                bp_details
            WHERE
                    tran_no = p_tran_no
                AND line_code IN ( 'ADJ_INTERCLASSCROSS' );

        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;

        IF ( nvl(l_inter_class_sub_adj, 0) != 0 ) THEN
            DELETE FROM bp_details
            WHERE
                    tran_no = p_tran_no
                AND line_code IN ( 'ADJ_INTERCLASSCROSS' );

            add_detail_line(p_tran_no, 'ADJ_INTERCLASS_SUBS', NULL, l_inter_class_sub_adj);
        END IF;

        l_2014_adj := nvl(l_gen_trans_adj, 0) + nvl(l_sysloss_lifeline_adj, 0) + nvl(l_inter_class_sub_adj, 0);

        p_2014_recovery_adj := l_2014_adj;
    EXCEPTION
        WHEN OTHERS THEN
            log_error('ADJUST_RECOVERY_ADJ_2014'
                      || p_sa_id
                      || ' Bill id:'
                      || p_bill_id, sqlerrm, 'Error in ADJUST_RECOVERY_ADJ_2014', NULL, NULL,
                     NULL, NULL);
    END adjust_recovery_adj_2014;

END bp_extract_pkg;
