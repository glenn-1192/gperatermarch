create or replace package body bp_extract_pkg
/*
   REVISION HISTORY
         v1.4.3 by gperater on March 6, 2024
                purpose of change :  new function created to get the amount of the BD SA in calc lines to be displayed on the bill for CR :  BD TOP UP
                                   get_bd_bseg_amt
                                  : new procedure created insert_bd_bseg , to get the details for BD SA and insertion to bp_details
                                   new config added in bp_detail_codes D-BILL
                                   revised proc extract_bills & extract_bills_rcoa : inserted the new function created get_bd_bseg_amt and 
                                   procedure insert_bd_bseg
               affected objects : new : get_bd_bseg_amt, insert_bd_bseg
                                  old : extract_bills, extract_bills_rcoa
               remarks          : revised procedure extract_bills & extract_bills_rcoa and new function created get_bd_bseg_amt and proc insert_bd_bseg
         v1.4.2 by gperater on January 30, 2024
                purpose of change : revised proc populate_bp_bir_2013 additional sum separate for line code RPT (Real Property Tax)
                                    as part of the requirement the said line is vatable but the existing set up is amount will be sum up to vat exempt
                affected objects : populate_bp_bir_2013
                remarks          : revised procs populate_bp_bir_2013

         v1.4.1 by gperater on January 10, 2024
                purpose of change : revised proc populate_bp_bir_2013 additional sum separate for line code FCT (Franchise Local Tax)
                                    as noted by the ops and b2c the said line is vatable but the existing set up is amount will be sum up
                                    to vat exempt
                                    : revised adjust_uc_spug minimize the decimal points for NPC-SPUG to 4 places
                affected objects : populate_bp_bir_2013, adjust_uc_spug
                remarks          : revised procs populate_bp_bir_2013 & adjust_uc_spug
         v1.4.0 by gperater on September 13, 2023
               purpose of change : newly created procedure to remove zero amounts on bp details
               affected objects : new, remove_zero_line_amt
                                  old, extract_bills
               remarks : newly created proc to remove zero amounts on bp details especially on adjustment charges that was part of the configuration of O/U recovery

        v1.3.9.6 by rreston on June 08, 2023
             Purpose of Change : revised existing proc adjust_uc_spug added more universal charges components true up 2013  and be
                          lump to NPC-SPUG
             Affected Objects  : old, adjust_uc_spug
                                 old, populate_bp_bir_2013
             Remarks           : revised existing procedure in relation to CM 1678: VECO New Transmission Charge Allocation / UCME true up
                                 removed <> condition for BIR 2306 PPVAT - Transco in procedure populate_bp_bir_2013


        v1.3.9.5 by jtan on December 20, 2022
             purpose of change : for tagging the ebill text accounts
             affected objects  : new:get_text_only_tag
                                 old:extract_bills
                                 old:extract_bills_rcoa
             remarks           : new:added a function for tagging the ebill text accounts
                                 old:alter table bp_headers and add new column txt_only
                                 old:revise the old procedure extract_bills/extract_bills_rcoa and inject the new function

        v1.3.9.4 by jtan on Dec 15, 2022
             Purpose of Change : To correct the bill presentment line rate for UC-ME-SPUG
             Affected Objects  : old procedure adjust_uc_spug
             Remarks           : as per SDP # 200204 and base on discussion commented the calcutions and hardcoded the exact line rate amount

        v1.3.9.3 by gperater on Sept 12, 2022
             Purpose of Change : get the line rate for the new line code UC-ME-SPUG
             Affected Objects  : new procedure adjust_uc_spug, added condition UC-ME-SPUG to be inserted to insert bp_detail_codes
             Remarks           : added a procedure in getting the line rate for UC-ME-SPUG

        v1.3.9.2 by rreston on Oct 25, 2021
             Purpose of Change : get the courier code for wheelings accounts
             Affected Objects  : get_default_courier
             Remarks           : add condition for wheeling accounts courier code

        v1.3.9.1 by SBAMIHAN on Sep 22, 2021
             Purpose of Change : To remove call to BPX.ebill_v2_pkg.publish_ebill_event()
                                 from the bottom of extract_bills() procedure
             Affected Objects  : extract_bills
             Remarks           : It is no longer needed.

        v1.3.9 by SBAMIHAN on May 21, 2021
             Purpose of Change : To publish an event to eBill 2.0
             Affected Objects  : extract_bills
             Remarks           : envoke BPX.ebill_v2_pkg.publish_ebill_event() after extracting single bill only.

        v1.3.8 by HNLIMPIO on July 24, 2020
             Purpose of Change : fix installment of ECQ bill lines
             Affected Objects  : add_ecq_info
             Remarks           : additional column, bx_count. Count should offset bills that has been canceled

        v1.3.7 by LGYAP on April 30, 2020
             Purpose of Change : ECQ related enhancements
             Affected Objects  : extract_bills
             Remarks           : additional procedure,add_ecq_info

        v1.3.6 by KDIONES on Aug 14, 2019
             Purpose of Change : 1175 VECO - Additional ID Format for 14 Digit TIN # in CCB
             Affected Objects  : get_tin
             Remarks           : adjust substring function from 16 to 20

        v1.3.5 by jlcomeros on March 15, 2019
            Purpose of Change : to support old and new version of BDS
            Affected Objects  : GET_BDMSGR
            Remarks           : get data first from CHAR_VAL otherwise from ADHOC_CHAR_VAL

        v 1.3.4 09.04.2018 jtan
            Purpose of Change : include due date details for autopay customers
            Affected Objects  : extract bills
            Remarks           : as per SDP # 135415

        v 1.3.3 04.06.2018 hnlimpio
            Purpose of Change : excluded BIR 2306 PPVAT-TVI
            Affected Objects  : insert_bp_details
            Remarks           : included in the query due to wrong configurations in CC

        v 1.3.2 03.12.2018 hnlimpio
            Purpose of Change : add commit in the proc update_no_alt_bill_id
            Affected Objects  : update_no_alt_bill_id
            Remarks           :

        v1.3.1 29-Sept-2017 jtan
            Purpose of Change : to update accounts that has no atl_bill_id for the current month.
            Affected Objects  : new:update_no_alt_bill_id
            Remarks           : update_no_alt_bill_id.

        v1.5.1 by JLCOMEROS on May 25, 2017
            Remarks           : add status validation for all script that access CI_BSEG table

        v1.5.0 by BCCONEJOS/JLCOMEROS on April 13, 2017
            Remarks           : bpx db has been separated from cisadm db, object types and collection types
                              cannot cross db links. transfered Insert Meter Details procedure to cisadm
                              as cm_bp_extract_util_pkg


        v1.4.1 07-APR-2017 AOCARCALLAS
            Purpose of Change : To fix some found potential error as per review.
            Affected Objects  : old:extract_bills
                              old:extract_bills_rcoa
            Remarks           : As requested to Review v1.3.0 and v1.4.0

        v1.4.0 by LGYAP on March 30, 2017
            Purpose of Change : This is to correct computation in BIR 2013 portion
            Affected Objects  : populate_bp_bir_2013
            Remarks           : Part of BIR Compliance

        v1.3.0 08-mar-2017 BCConejos
            Purpose of Change : modify table where ebill_accounts are tagged
                               old table is ebill_accounts
                               new table is ebill_statement_accounts

        v1.2.0 02-FEB-2017 AOCARCALLAS
            Purpose of Change : additional functions  to populate the business address, business style
            Affected Objects  : new:get_business_style
                              new:retrieve_business_address
                              old:get_tin
                              old:extract_bills
            Remarks           : part of BIR compliance (scripts copy from SEZC v1.2.0)

        version 16.06.24
            revised on : June 24, 2016
            revised by : jlcomeros
            remarks    : revise procedure INSERT_RCOAGEN_BP_DETAILS
                        - add filter BSEG_STAT_FLG when getting kwh consumption

        version 16.04.18
            revised on : April 18, 2016
            revised by : aocarcallas
            remarks    : update procedure bill_print_sweeper
                      : bill extraction for the last two days (complete date - 2).

        version 16.03.29
            revised on : mar 29, 2016
            revised by : aocarcallas
            remarks    : new procedure bill_print_sweeper
                      : bill extraction for yesterday's unextracted bills

        version 16.03.11.01
            revised on : mar 11, 2016
            revised by : lgyap
            remarks    : uppdate procedure POPULATE_BILL_MSG_PARAM, for the lumped bill message parameters

        version 15.09.18
            revised on : sep 18, 2015
            revised by : lgyap
            remarks    : restoring back the old procedure, insert_meter_details (old_insert_meter_details).
                        this is intended for the accounts being billed using the old process

        version 15.07.31
            revised on : jul 31, 2015
            revised by : lgyap
            remarks    : revision in procedure, adjust_uc_MEs to delete including the code, UME-RCOA.

        version 2015.05.29
            revised on : may 29, 2015
            revised by : lgyap
            remarks    : additional condition,  or (l_bph.rate_schedule like '%IR%')
                        to include the newly transfered TOU accounts in the process of getting TOU Metering Info

        version 2015.05.20
            revised on : may 20, 2015
            revised by : lgyap
            remarks    : new producedure that will separate DU_SET_ID of power  rate customers from regular customers

        version 2015.05.07
            revised on : may 07, 2015
            revised by : lgyap
            remarks    : new procedure update_alt_id_2_zero
                      : adjusting alt bill ids of adhoc bills created prior to CAS deployment

        version 2015.03.31
            revised on : mar 31, 2015
            revised by : lgyap
            remarks    : revision of procedure, extract_bills for the ALT_BILL_ID
                        new procedure that updates the alt_bill_id of adhoc bills

        version 2014.09.15.01
            revised on : sept 15, 2014
            revised by : lgyap
            remarks    : revision of function get_courier_code - function will just log the account whenever it encounters an error

        version 2014.09.04.01
            revised on : sept 04, 2014
            revised by : lgyap
            remarks    : revision in procedure extract_bills to exclude RCOA Bills

        version 2014.07.21
            revised on : july 21, 2014
            revised by : lgyap
            remarks    : additional: procedure for populating bill message parameters

        version 2014.05.28.01
            revised on : may 28, 2014
            revised by : lgyap
            remarks    : addtional package for adjustment of TOU bills

        version 2014.05.16.01
            revised on : may 16, 2014
            revised by : lgyap
            remarks    : revision of the procedure populate_bir_2013
                        for the computation of vat zero rated accounts

        version 2014.03.25.01
            revised on : mar 25, 2014
            revised by : lgyap
            remarks    : revision of procedure adjust_uc_MEs,
                        adding exception handler that will bypass and log the erroneous bills

        version 2014.03.06
            revised on : mar 06, 2014
            revised by : lgyap
            remarks    : revision on the procedure UPDATE_BILL_MESSAGES additional exception, when dup_val_on_index while
                        while inserting bp_message_codes

        version 2014.03.05.01
            revised on : mar 05, 2014
            revised by : lgyap
            remarks    : additional procedure for the updating of bill messages, UPDATE_BILL_MESSAGES

        version 2014.02.06.01
            revised on : feb 06, 2014
            revised by : lgyap
            remarks    : revision of the procedure extract_bills for the new parameter, complete_date

        version 2014.01.29.01
            revised on : jan 29, 2014
            revised by : lgyap
            remarks    : revision of the procedure adjust_uc_MEs for the new calc, uc missionary electrification 3,
                        and revision of procedure populate_bir_2013 for the current bill amount to be reflected on the bill

        version 2014.01.16.01
            revised on : jan 16, 2014
            revised by : lgyap
            remarks    : revision in extract_bills for the net metering

        version 2014.01.08.01
            revised on : jan 08, 2014
            revised by : lgyap
            remarks    : revision in insert_bp_details procedure for the missionary electrification details

        version 1.2.0
            revised on : oct 14, 2013
            remarks    : reviewed procedure, populate_bp_bir_2013
                        for the wrong calculation found

        version 1.1.9
            revised on : aug 19, 2013
            remarks    : additional functions and procedures for BIR requirements
                        function get_tin , this function will return tin of the customer
                        procedures populate_bir_2013_requirements
                        this procedure will populate necessary data for BIR requirements such as:
                        total vat amount,
                        bir 2306,
                        bir 2307,
                        senior citizen discounts,
                        and pwd discount


        version 1.1.8
            revised on : april 30, 2013
            remarks    : revision in procedure insert_consumption_hist
                        to have 13 columns in bill graph

        version 1.1.7
            revised on : april 23, 2013
            remarks    : revision in procedure extract_bills.
                        for per bill extraction, control batch number will not be incremented

        version 1.1.6
            revised on : jan 15, 2013
            revised by : lgyap
            remarks    : revision in procedure extract_bills for the ebill_only_sw column

        version 1.1.5
            revised on : dec 06, 2012
            revised by : lgyap
            remarks    : revision in procedure extract_bills for no_batch_prt_sw

        version 1.1.4
            revised on : aug 14,2012
            revised by : lgyap
            remarks    : revision in procedure extract_bills, remove clause and not exists (select null from bp_headers where bill_no = b.bill_id) @ cursor bill_routes_cur

        version 1.1.3
            revised on : aug 10, 2012
            revised by : lgyap
            remarks    : revision in procedure extract_bills, program will not continue loading the bill when already inserted in bp_headers

        version 1.1.2
            revised on : july 09, 2012
            revised by : lgyap
            remarks    : line for accounts with auto debit/credit

        version 1.1.1
            revised on : apr 30, 2012
            revised by : lgyap
            remarks    : line for GSL adjustments
                        revision in  function get_bill_message, message code to be retrieved is base from the bill message priority
                        revision in procedure insert_adj for the line Adjustment for PBR Guaranteed Service Level

        version 1.1.0
            revised on : jan 24, 2012
            revised by : lgyap
            remarks    : revision in existing procedure insert_bp_details, to separate PAR line from other calc lines
                        additional function insert_detail_4par, get_par_month

        version 1.0.9
            revised on : nov 17, 2011
            revised by : lgyap
            remarks    : revised in procedure extract_bills, get overdue amount even if bill is green

        version 1.0.8
            revised on : nov 10, 2011
            revised by : lgyap
            remarks    : revision in function get_book_no, for the bug found.
                        accounts affected are with disconnected or abolished SP

        version 1.0.7
            revised on : oct 26, 2011
            revised by : bmtorrenueva
            remarks    : revision in fuction get_book_no; the function is returning the abolished/disconnected service point
                        thus it is showing the wrong book no presented in the bill.

        version 1.0.6
            revised on : oct 20, 2011
            revised by : lgyap
            remarks    : revision in fuction extract_bills for TOU billing (NOSP-RAT)
                      : revision in procedure insert_bp_details, to remove character sets: /KWH, /KW &/month

        version 1.0.5
            revised on : april 15, 2011
            revised by : lgyap
            remarks    : new function created for bill delivery messenger code

        version 1.0.4
            revised on : march 16, 2011
            revised by : bmtorrenueva
            remarks    : revised the procedure get bill delivery sequence no: (null values) numeric or value error

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

        version 1.0.2
            revised on  : august 14, 2015
            revised by  : samihan
            remarks     : remapped meter read info from ci_bseg_read to cisadm.c1_usage using cm_bill_usage_pkg.read() function

*/
 is

    procedure remove_zero_line_amt (p_tran_no in number)
    as

    begin
     delete from bp_details
           where line_code in ('GEN-CHRADJ',
                               'GEN-CHRADJ_W',
                               'SL-CHRADJ',
                               'SL-CHRADJ_W',
                               'SYS-CHRADJ',
                               'SYS-CHRADJ_W',
                               'TRX-CHRADJ',
                               'TRX-CHRADJ_N',
                               'TRX-CHRADJ_W'
                               )
           and   line_amount = 0
           and   tran_no = p_tran_no;

    end remove_zero_line_amt;
    
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
      
       exception
            when others then
                log_error('GET_BD_BSEG_AMT ' || p_bill_no,
                          sqlerrm,
                          'Error in retrieving BD bseg amount',
                          null,
                          null,
                          null,
                          null);
      
      --return(l_bd_amt);
    
    end;

    function get_text_only_tag(p_acct_id in varchar2) return varchar2 as
        l_txt_only varchar2(1);
    begin
        begin
            l_txt_only := 'N';

            select 'Y'
            into   l_txt_only
            from   ci_acct_char
            where  char_type_cd = 'PRISMSNO'
            and    acct_id = p_acct_id;
        exception
            when no_data_found then
                l_txt_only := 'N';
            when too_many_rows then
                l_txt_only := 'Y';
        end;

        return l_txt_only;
    end;

    function get_lpc(p_bill_id in varchar2) return number as
        l_lpc_amt number := 0;
    begin
        begin

            select /*+RULE*/
             nvl(sum(cur_amt), 0) lpc_amount
            into   l_lpc_amt
            from   ci_ft ft
            where  ft.bill_id = p_bill_id
            and    ft.ft_type_flg = 'AD'
            and    parent_id = 'SURCHADJ';
        exception
            when others then
                log_error('GET_LPC ' || p_bill_id,
                          sqlerrm,
                          'Error in retrieving lpc amount',
                          null,
                          null,
                          null,
                          null);
                l_lpc_amt := 0;
        end;

        return l_lpc_amt;
    end;

    function get_overdue_amt90(p_bill_no in varchar2) return number is
        l_elec_bal number;
        l_xfer_amt number;
        l_prev_bal number;
    begin
        /*
          2020.06.04 - BCC : changed script to get previous balance
            to match how CC gets the previous balance for the Bill
            the Arrears date is not considered
        */
        begin
            select prev_balance
            into   l_elec_bal
            from   (with bill as (select b.acct_id,
                                         b.bill_dt,
                                         b.bill_id,
                                         b.complete_dttm,
                                         cre_dttm
                                  from   ci_bill b
                                  where  b.bill_id = p_bill_no), prev_trans as (select nvl(sum(cur_amt),
                                                                                           0) sum_prev_trans
                                                                                from   ci_ft ft,
                                                                                       ci_sa sa,
                                                                                       ci_sa_type sat,
                                                                                       bill b
                                                                                where  sa.sa_id =
                                                                                       ft.sa_id
                                                                                and    sa.acct_id =
                                                                                       b.acct_id
                                                                                and    sa.sa_type_cd =
                                                                                       sat.sa_type_cd
                                                                                and    sat.debt_cl_cd <>
                                                                                       'DEP'
                                                                                      --and    ars_dt <= b.bill_dt -- commented out by BCC
                                                                                and    ft.bill_id <>
                                                                                       b.bill_id
                                                                                and    ft.freeze_dttm <
                                                                                       b.complete_dttm -- modified by BCC
                                                                                ), bill_sweep as (select nvl(sum(cur_amt),
                                                                                                             0) sum_bill_sweep
                                                                                                  from   ci_ft ft,
                                                                                                         ci_sa sa,
                                                                                                         ci_sa_type sat,
                                                                                                         bill b
                                                                                                  where  sa.sa_id =
                                                                                                         ft.sa_id
                                                                                                  and    sa.acct_id =
                                                                                                         b.acct_id
                                                                                                  and    sa.sa_type_cd =
                                                                                                         sat.sa_type_cd
                                                                                                  and    sat.debt_cl_cd <>
                                                                                                         'DEP'
                                                                                                  and    (ft.ft_type_flg in
                                                                                                        ('PS',
                                                                                                           'PX') or
                                                                                                        (ft.ft_type_flg = 'BX' and
                                                                                                        ft.parent_id <>
                                                                                                        ft.bill_id))
                                                                                                  and    ft.bill_id =
                                                                                                         p_bill_no)
                       select (sum_prev_trans + sum_bill_sweep) prev_balance,
                              sum_prev_trans,
                              sum_bill_sweep
                       from   prev_trans, bill_sweep);


            -- commented out by BCC
            /* select sum(abs(cur_amt))/2
               into l_xfer_amt
             from ci_ft ft1
            where bill_id = p_bill_no
              and parent_id = 'XFERPA2'*/

            select sum(cur_amt)
            into   l_xfer_amt
            from   ci_ft ft, ci_sa sa
            where  sa.sa_id = ft.sa_id
            and    ft.bill_id = p_bill_no
            and    ft.parent_id = 'XFERPA2'
            and    sa.sa_type_cd = 'PA-ECQ';

            l_prev_bal := nvl(l_elec_bal, 0) - nvl(l_xfer_amt, 0);

        exception
            when no_data_found then
                null;
        end;
        return(l_prev_bal);
    end get_overdue_amt90;

    procedure add_ecq_info(p_tran_no      in number,
                           p_bill_id      in varchar2,
                           p_tot_bill_amt number) as
        /*
            v1.3.7 by LGYAP on April 30, 2020
                 Purpose of Change : ECQ related enhancements
                 Remarks           : add_ecq_info
        */

        l_ecq_bal         number;
        l_outstanding_amt number;
        l_bs_count        number;
        l_terms           varchar2(20);
        l_pa_sa_id        varchar2(20);
        l_line            number;
        l_xfer_amt        number;
    begin
        begin
            l_line := 10;
            select sa.sa_id
            into   l_pa_sa_id
            from   ci_bseg bseg, ci_sa sa
            where  bseg.sa_id = sa.sa_id
            and    sa_type_cd = 'PA-ECQ'
            and    sa.sa_status_flg = '20'
            and    bseg.bseg_stat_flg = '50'
            and    bseg.bill_id = p_bill_id;

            -- adjusting nCCBADJ:Credit Adjustment
            declare
                l_adj_amt    number;
                l_xfer_amt   number;
                l_xfer_count number;
            begin
                l_line := 12;
                select line_amount
                into   l_adj_amt
                from   bp_details
                where  tran_no = p_tran_no
                and    line_code = 'nCCBADJ';

                l_line := 14;
                select nvl(count(*), 0), sum(cur_amt)
                into   l_xfer_count, l_xfer_amt
                from   ci_ft
                where  sa_id = l_pa_sa_id
                and    bill_id = p_bill_id
                and    parent_id in ('XFERPA2');

                if l_xfer_count = 1
                then
                    if l_adj_amt = (l_xfer_amt) * (-1)
                    then
                        l_line := 15;
                        delete from bp_details
                        where  tran_no = p_tran_no
                        and    line_code = 'nCCBADJ';

                    elsif l_adj_amt <> (l_xfer_amt * (-1))
                    then
                        l_line := 16;
                        update bp_details
                        set    line_amount = line_amount -
                                             (l_xfer_amt) * (-1)
                        where  tran_no = p_tran_no
                        and    line_code = 'nCCBADJ';
                    end if;

                    /*   --updating previous amount
                    l_line := 17;
                    update bp_details
                       set line_amount = line_amount - (l_xfer_amt)
                     where tran_no = p_tran_no
                       and line_code = 'OVERDUE';*/
                end if;

            exception
                when no_data_found then
                    null;
            end;

            begin

                l_line := 20;
                select ft2.ecq_bal, (bs_count - bx_count) bs_count2, terms
                into   l_ecq_bal, l_bs_count, l_terms
                from   (select ft.*,
                               ft.run_bal - run_cur ecq_bal,
                               sum(decode(ft.ft_type_flg, 'BS', 1, 0)) over(partition by ft.grp order by ft.freeze_dttm) as bs_count,
                               sum(decode(ft.ft_type_flg, 'BX', 1, 0)) over(partition by ft.grp order by ft.freeze_dttm) as bx_count,
                               trim(sac.adhoc_char_val) terms
                        from   (select ft_id,
                                       sa_id,
                                       parent_id,
                                       ft_type_flg,
                                       cur_amt,
                                       tot_amt,
                                       freeze_dttm,
                                       sum(cur_amt) over(order by freeze_dttm) as run_cur,
                                       sum(tot_amt) over(order by freeze_dttm) as run_bal,
                                       max(decode(parent_id,
                                                  'SYNC-PA     ',
                                                  freeze_dttm)) over(order by freeze_dttm) grp
                                from   ci_ft
                                where  sa_id = l_pa_sa_id) ft,

                               ci_sa_char sac
                        where  ft.sa_id = sac.sa_id
                        and    sac.char_type_cd = 'PATERM') ft2
                where  ft2.parent_id = p_bill_id;

                l_terms := to_char(l_bs_count) || ' of ' || l_terms;
            exception
                when too_many_rows then
                    begin
                        select nvl(ecq_bal, 0)
                        into   l_ecq_bal
                        from   (select ft.run_bal - run_cur ecq_bal,
                                       max(freeze_dttm) over() max_freeze,
                                       ft.freeze_dttm
                                from   (select ft_id,
                                               sa_id,
                                               parent_id,
                                               ft_type_flg,
                                               cur_amt,
                                               tot_amt,
                                               freeze_dttm,
                                               sum(cur_amt) over(order by freeze_dttm) as run_cur,
                                               sum(tot_amt) over(order by freeze_dttm) as run_bal
                                        from   ci_ft
                                        where  sa_id = l_pa_sa_id) ft
                                where  parent_id = p_bill_id)
                        where  freeze_dttm = max_freeze;

                    exception
                        when no_data_found then
                            l_ecq_bal := 0;
                    end;

                    l_terms := null;
            end;

            l_outstanding_amt := l_ecq_bal + p_tot_bill_amt;

            l_line := 30;
            update bp_details
            set    line_rate = l_terms
            where  tran_no = p_tran_no
            and    line_code = 'PA-ECQ';

            l_line := 35;
            insert into bp_details
                (tran_no, line_code, line_rate, line_amount)
            values
                (p_tran_no, 'ECQ_SPACE', null, null);

            l_line := 40;
            insert into bp_details
                (tran_no, line_code, line_rate, line_amount)
            values
                (p_tran_no, 'ECQ_BAL', null, l_ecq_bal);

            l_line := 50;
            insert into bp_details
                (tran_no, line_code, line_rate, line_amount)
            values
                (p_tran_no, 'TOT_W_ECQ', null, l_outstanding_amt);

            --deleting lines with zero amounts
            l_line := 60;
            begin
                delete from bp_details
                where  tran_no = p_tran_no
                and    line_amount = 0
                and    line_code not in ('OVERDUE',
                                         'PREVAMTSPACER',
                                         'CURCHARGES',
                                         'vGENCHGHDR',
                                         'GEN',
                                         'TRX-KW',
                                         'SYS',
                                         'vGENTRANSTOT',
                                         'vDISTREVHDR',
                                         'DIST',
                                         'SFX',
                                         'MFX',
                                         'vDISTREVTOT',
                                         'vOTHHDR',
                                         'SLF-C',
                                         'R-SLF',
                                         'PF-P',
                                         'vOTHTOT',
                                         'vGOVREVHDR',
                                         'FCT',
                                         'vVATHDR',
                                         'VAT-DIS',
                                         'vUNIVCHGHDR',
                                         'UC-MES',
                                         'UEC',
                                         'vGOVTOT',
                                         'CURBIL',
                                         'PA-ECQ',
                                         'NETSPACER',
                                         'OUTAMT',
                                         'CCBREDNOTICE',
                                         'CCBNOTICE1',
                                         'ECQ_SPACE',
                                         'ECQ_BAL',
                                         'TOT_W_ECQ',
                                         'CCBNOTICE');
            end;

        exception
            when no_data_found then
                null;
        end;

    exception
        when others then
            log_error('add_ecq_info SA ID:' || l_pa_sa_id || ' Bill id:' ||
                      p_bill_id,
                      sqlerrm,
                      'Error in populating ecq info @ line: ' ||
                      to_char(l_line),
                      null,
                      null,
                      null,
                      null);

    end add_ecq_info;

    procedure update_no_alt_bill_id as
        /*

          v1.3.1 29-Sept-2017 jtan
            Remarks : created procedure that will update no_alt_bill_id.
        */

    begin
        update bpx.bp_headers hdr
        set    hdr.alt_bill_id =
               (select alt_bill_id
                from   bpx.ci_bill
                where  bill_id = hdr.bill_no)
        where  hdr.bill_month = trunc(sysdate, 'MM')
        and    nvl(hdr.alt_bill_id, 0) = '0';

        commit;
    exception
        when others then
            rollback;
            raise;
    end;

    procedure log_error(p_action           in varchar2,
                        p_oracle_error_msg in varchar2,
                        p_custom_error_msg in varchar2 default null,
                        p_table_name       in varchar2 default null,
                        p_pk1              in varchar2 default null,
                        p_pk2              in varchar2 default null,
                        p_pk3              in varchar2 default null) as
        pragma autonomous_transaction;
    begin
        insert into error_logs
            (logged_by,
             logged_on,
             module,
             action,
             oracle_error_msg,
             custom_error_msg,
             table_name,
             pk1,
             pk2,
             pk3)
        values
            (user,
             sysdate,
             'BP_EXTRACT_PKG',
             p_action,
             p_oracle_error_msg,
             p_custom_error_msg,
             p_table_name,
             p_pk1,
             p_pk2,
             p_pk3);

        dbms_application_info.set_action('Error Encountered.');
        commit;
    end log_error;

    function get_business_style(p_sa_id in varchar2) return varchar2 as
        --Version History
        /*--------------------------------------------------------
           v1.2.0 02-FEB-2017 AOCARCALLAS
           Remarks : this function will return the Business Style of the particular customer

        */
        --------------------------------------------------------
        l_business_style varchar2(250);
    begin
        begin
            select bus_activity_desc
            into   l_business_style
            from   ci_sa
            where  sa_id = p_sa_id;
        exception
            when others then
                log_error('get_business_style',
                          sqlerrm,
                          'Error in retrieving business styel',
                          'CI_SA',
                          p_sa_id,
                          null,
                          null);
        end;

        return l_business_style;
    end get_business_style;

    procedure retrieve_business_address(p_acct_id  in varchar2,
                                        p_address1 in out varchar2,
                                        p_address2 in out varchar2,
                                        p_address3 in out varchar2,
                                        p_address4 in out varchar2,
                                        p_address5 in out varchar2) as
        --Version History
        /*--------------------------------------------------------
           v1.2.0 01-FEB-2017 AOCARCALLAS
           Remarks : this function will return the Business Address of the particular customer

        */
        --------------------------------------------------------
    begin
        begin
            select p.address1, p.address2, p.address3, p.address4, p.city
            into   p_address1,
                   p_address2,
                   p_address3,
                   p_address4,
                   p_address5
            from   ci_acct_per ap, ci_per p
            where  ap.per_id = p.per_id
            and    ap.acct_id = p_acct_id
            and    ap.acct_rel_type_cd = 'MAINCU  '
            and    ap.main_cust_sw = 'Y';
        exception
            when no_data_found then
                p_address1 := null;
                p_address2 := null;
                p_address3 := null;
                p_address4 := null;
                p_address5 := null;
            when others then
                log_error('Retrieving premise address.',
                          sqlerrm,
                          'p_acct_id',
                          null,
                          p_acct_id,
                          null,
                          null);
        end;
    end retrieve_business_address;

    procedure bill_print_sweeper as
        l_du_set_id number;
    begin
        l_du_set_id := to_number(to_char(sysdate, 'YYYYMMDD'));

        for l_cur in (select br.batch_cd, br.batch_nbr, br.bill_id
                      from   ci_bill_char bchar,
                             ci_bill b,
                             ci_bill_routing br
                      where  bchar.char_type_cd = 'BILLIND '
                      and    bchar.bill_id = b.bill_id
                      and    b.bill_stat_flg = 'C'
                      and    b.complete_dttm >= trunc(sysdate) - 2
                      and    b.complete_dttm < trunc(sysdate) + 1
                      and    br.bill_id = b.bill_id
                      and    br.bill_rte_type_cd in ('POSTAL', 'POSTAL2')
                      and    not exists
                       (select null
                              from   bp_headers h
                              where  h.bill_no = b.bill_id))
        loop
            declare
                l_errmsg varchar2(1000);
            begin
                bp_extract_pkg.extract_bills(l_cur.batch_cd,
                                             l_cur.batch_nbr,
                                             l_du_set_id,
                                             1,
                                             null,
                                             null,
                                             l_cur.bill_id);
            exception
                when others then
                    l_errmsg := sqlerrm;
                    rollback;
                    log_error('Extract yesterday''s remaining unextracted bills',
                              l_errmsg,
                              'Error encountered while extracting the remaining bills',
                              'CI_BILL_ROUTING',
                              l_cur.bill_id,
                              null,
                              null);
            end;
        end loop;
    end bill_print_sweeper;

    function get_extract_bill_count(p_batch_cd  in varchar2,
                                    p_batch_nbr in number) return number is
        l_extract_bill_count number;
    begin
        begin
            select count(*)
            into   l_extract_bill_count
            from   ci_bill_routing br
            where  br.bill_rte_type_cd in ('POSTAL', 'POSTAL2')
            and    br.seqno = 1 -- just get the first entry in the bill routing
            and    br.batch_cd = rpad(p_batch_cd, 8)
            and    br.batch_nbr = p_batch_nbr
            and    not exists
             (select null from bp_headers where bill_no = br.bill_id);
        exception
            when others then
                log_error('Counting bills for Extraction',
                          sqlerrm,
                          null,
                          null,
                          p_batch_cd,
                          p_batch_nbr,
                          null);
                raise_application_error(-20010, sqlerrm);
        end;

        return(l_extract_bill_count);
    end;

    function generate_du_set_id return number is
        l_du_set_id number;
    begin
        begin
            select bph_du_set_ids.nextval into l_du_set_id from dual;
        exception
            when others then
                log_error('Generating du_set_id.',
                          sqlerrm,
                          null,
                          'bph_du_set_ids',
                          null,
                          null,
                          null);
                raise_application_error(-20020,
                                        'Generating du_set_id: ' || sqlerrm);
        end;

        return(l_du_set_id);
    end;

    function get_crc(p_acct_id in varchar2) return varchar2 is
        l_crc ci_acct_char.adhoc_char_val%type;
    begin
        begin
            select adhoc_char_val
            into   l_crc
            from   ci_acct_char ac
            where  ac.acct_id = p_acct_id
            and    ac.char_type_cd = 'CRCCODE';
        exception
            when no_data_found then
                l_crc := 'NO-CRC';
            when too_many_rows then
                l_crc := 'MULTI-CRC';
            when others then
                log_error('Getting CRC.',
                          sqlerrm,
                          'Acct_id',
                          null,
                          p_acct_id,
                          null,
                          null);
                raise_application_error(-20030,
                                        p_acct_id || ' ' || sqlerrm);
        end;

        return(l_crc);
    end;

    function get_bdseq(p_acct_id in varchar2) return varchar2
    -- this is the new function for getting the bill delivery sequence
        -- used when the bdseq is added as a characteristic for the account
     is
        l_bdseq ci_acct_char.adhoc_char_val%type;
    begin
        begin
            select nvl(trim(adhoc_char_val), 0)
            into   l_bdseq
            from   (select adhoc_char_val
                    from   ci_acct_char ac
                    where  ac.acct_id = p_acct_id
                    and    ac.char_type_cd = 'CM_BDSEQ'
                    order  by effdt desc)
            where  rownum = 1;
        exception
            when no_data_found then
                --l_bdseq := null;
                l_bdseq := 0;
            when others then
                log_error('Getting Bill Delivery Sequence.',
                          sqlerrm,
                          'Acct_id',
                          null,
                          p_acct_id,
                          null,
                          null);
                raise_application_error(-20030,
                                        p_acct_id || ' ' || sqlerrm);
        end;

        return(l_bdseq);
    end;

    function get_bdmsgr(p_acct_id in varchar2) return varchar2 is
        l_bdmsgr ci_acct_char.adhoc_char_val%type;
    begin
        /*
         begin
             select adhoc_char_val
             into   l_bdmsgr
             from   (select adhoc_char_val
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
                 raise_application_error (-20030, p_acct_id || ' ' || sqlerrm);
         end;
        */

        select max(nvl(trim(char_val), adhoc_char_val)) keep(dense_rank first order by effdt desc) msgr_code
        into   l_bdmsgr
        from   ci_acct_char ac
        where  ac.acct_id = p_acct_id
        and    ac.char_type_cd = 'CM_BDMSR';

        return(l_bdmsgr);
    end get_bdmsgr;

    procedure retrieve_rate_schedule(p_bill_id  in varchar2,
                                     p_sa_id    in varchar2,
                                     p_rs_cd    in out varchar2,
                                     p_rs_descr in out varchar2) is
    begin
        select max(trim(bsc.rs_cd)), max(trim(rl.descr))
        into   p_rs_cd, p_rs_descr
        from   ci_bseg bs, ci_bseg_calc bsc, ci_rs_l rl
        where  bs.bseg_id = bsc.bseg_id
        and    bsc.rs_cd = rl.rs_cd
        and    rl.language_cd = 'ENG'
        and    bs.bseg_stat_flg in ('50', '70')
        and    bs.bill_id = p_bill_id
        and    bs.sa_id = p_sa_id;
    exception
        when no_data_found then
            p_rs_cd := null;
            p_rs_descr := null;
        when others then
            log_error('Retrieving rate schedule.',
                      sqlerrm,
                      'bill_id/sa_id',
                      null,
                      p_bill_id,
                      p_sa_id,
                      null);
            raise_application_error(-20040,
                                    'bill_id/sa_id: ' || p_bill_id || '/' ||
                                    p_sa_id || ' ' || sqlerrm);
    end;

    function get_default_courier(p_rs_cd      in varchar2,
                                 p_bill_cycle in varchar2,
                                 p_acct_no    in varchar2) return varchar2 is
        --Version History
        /*--------------------------------------------------------
           v1.3.9.2 by rreston on Oct 25, 2021
                 Remarks : add condition for wheeling accounts courier code

        */
        --------------------------------------------------------
        l_courier_code bp_courier_codes.courier_code%type;
    begin
        begin
            if to_number(substr(p_rs_cd, 6, 2)) >= 50
            then
                --= '06-P-60W' then
                l_courier_code := 'P';
            elsif to_number(substr(p_rs_cd, -2)) <= 33
            then
                l_courier_code := '33';
            elsif to_number(substr(p_rs_cd, -2)) > 33 and
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
        exception
            when others then
                log_error('function get_default_courier',
                          sqlerrm,
                          'acct_id',
                          null,
                          p_acct_no,
                          null,
                          null);
                l_courier_code := 'ADHOC';
        end;

        if l_courier_code is null
        then
            log_error('function get_default_courier',
                      'not in the above conditions',
                      'acct_id',
                      null,
                      p_acct_no,
                      null,
                      null);
            l_courier_code := 'ADHOC';
        end if;

        return(l_courier_code);
    end;

    procedure retrieve_last_payment(p_acct_id       in varchar2,
                                    p_bill_date     in date,
                                    p_last_pay_date in out date,
                                    p_last_pay_amt  in out number) is
    begin
        begin
            select a.pay_dt, a.pay_amt
            into   p_last_pay_date, p_last_pay_amt
            from   (select event.pay_dt, pay.pay_amt
                    from   ci_pay_event event, ci_pay pay
                    where  event.pay_event_id = pay.pay_event_id
                    and    pay.acct_id = p_acct_id
                    and    pay.pay_status_flg = '50'
                    and    event.pay_dt <= p_bill_date
                    order  by event.pay_dt desc) a
            where  rownum = 1;
        exception
            when no_data_found then
                p_last_pay_date := null;
                p_last_pay_amt := null;
            when others then
                log_error('Retrieving last payment date/amount.',
                          sqlerrm,
                          'acct_id/bill_dt',
                          null,
                          p_acct_id,
                          to_char(p_bill_date, 'yyyy/mm/dd'),
                          null);

                raise_application_error(-20050, sqlerrm);
        end;
    end;

    procedure retrieve_premise_address(p_prem_id  in varchar2,
                                       p_address1 in out varchar2,
                                       p_address2 in out varchar2,
                                       p_address3 in out varchar2) is
    begin
        begin
            select address1, address2, address3
            into   p_address1, p_address2, p_address3
            from   ci_prem p
            where  p.prem_id = p_prem_id;
        exception
            when no_data_found then
                p_address1 := null;
                p_address2 := null;
                p_address3 := null;
            when others then
                log_error('Retrieving premise address.',
                          sqlerrm,
                          'prem_id',
                          null,
                          p_prem_id,
                          null,
                          null);
                raise_application_error(-20060,
                                        'Retrieving Premise address: ' ||
                                        p_prem_id || ' ' || sqlerrm);
        end;
    end;

    function get_area_code(p_city in varchar2) return number as
        l_ret  number;
        l_code varchar2(30);
    begin
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

        return l_ret;
    end get_area_code;

    function get_book_no(p_sa_id in varchar2) return number is
        l_book_no number;
    begin
        begin
            select max(to_number(mr_rte_cd))
            into   l_book_no
            from   ci_sp sp, ci_sa_sp sap
            where  sp.sp_id = sap.sp_id
            and    usage_flg = '+'
            and    sp.sp_status_flg = 'R ' -- in service (added this two lines bmtorrenueva 20111026)
            and    sp.sp_src_status_flg = 'C ' -- connected
            and    sap.sa_id = p_sa_id;

            if l_book_no is null
            then
                select max(to_number(mr_rte_cd))
                into   l_book_no
                from   ci_sp sp, ci_sa_sp sap
                where  sp.sp_id = sap.sp_id
                and    usage_flg = '+'
                and    sp.sp_status_flg = 'R '
                and    sap.sa_id = p_sa_id;

                if l_book_no is null
                then
                    select max(to_number(mr_rte_cd))
                    into   l_book_no
                    from   ci_sp sp, ci_sa_sp sap
                    where  sp.sp_id = sap.sp_id
                    and    usage_flg = '+'
                    and    sp.sp_status_flg = 'I '
                    and    sap.sa_id = p_sa_id;
                end if;
            end if;
        exception
            when others then
                log_error('function GET_BOOK_NO',
                          sqlerrm,
                          'SA ID : ' || p_sa_id,
                          'CI_SP',
                          null,
                          null,
                          null);

                l_book_no := 0;
        end;

        return l_book_no;
    end;

    function get_delivery_sequence(p_acct_id in varchar2) return number is
        l_delivery_sequence number;
    begin
        -- gets the delivery sequence from the materialized view
        -- however as new accts are being built up on ccnb
        -- delivery sequence of the new accts will not be reflected on the mview
        -- suggest to put the delivery sequence as a characteristic of the acct or person
        begin
            select delivery_sequence
            into   l_delivery_sequence
            from   billdel_sequences
            where  acct_id = p_acct_id;
        exception
            when no_data_found then
                l_delivery_sequence := null;
            when others then
                dbms_application_info.set_action('Error Encountered.');
                raise_application_error(-20004, sqlerrm);
        end;

        return(l_delivery_sequence);
    end;

    function get_bill_sq(p_bill_id in varchar2,
                         p_sa_id   in varchar2,
                         p_sqi_cd  in varchar2,
                         p_uom_cd  in varchar2 default null) return number is
        l_bill_sq number;
    begin
        begin
            select max(bill_sq)
            into   l_bill_sq
            from   ci_bseg bs, ci_bseg_sq bsq
            where  bs.bseg_id = bsq.bseg_id
            and    bs.bseg_stat_flg in ('50', '70')
            and    bs.bill_id = p_bill_id
            and    bs.sa_id = p_sa_id
            and    sqi_cd = rpad(p_sqi_cd, 8)
            and    nvl(trim(uom_cd), '00') =
                   nvl(p_uom_cd, nvl(trim(uom_cd), '00'));
        exception
            when no_data_found then
                l_bill_sq := null;
            when others then
                l_bill_sq := 0;
        end;

        return(l_bill_sq);
    end;

    function get_current_bill_amt(p_bill_id in varchar2,
                                  p_sa_id   in varchar2) return number is
        l_current_bill_amt number;
    begin
        begin
            select bc.calc_amt
            into   l_current_bill_amt
            from   ci_bseg bs, ci_bseg_calc bc
            where  bs.bseg_id = bc.bseg_id
            and    bc.header_seq = 1
            and    bs.bseg_stat_flg in ('50', '70')
            and    bs.bill_id = p_bill_id
            and    bs.sa_id = p_sa_id;
        exception
            when others then
                log_error('Getting current billed amount.',
                          sqlerrm,
                          null,
                          null,
                          p_bill_id,
                          p_sa_id,
                          null);
                l_current_bill_amt := 0;
        end;

        -- add late payment charge/surcharge
        l_current_bill_amt := l_current_bill_amt + get_lpc(p_bill_id);

        return(l_current_bill_amt);
    end;

    function get_net_bill_amt(p_bill_id in varchar2) return number is
        l_net_bill_amt number;
    begin
        begin
            select sum(cur_amt)
            into   l_net_bill_amt
            from   ci_bill_sa b
            where  b.bill_id = p_bill_id;
        exception
            when others then
                log_error('Getting net billed amount.',
                          sqlerrm,
                          null,
                          null,
                          p_bill_id,
                          null,
                          null);
                raise_application_error(-20171,
                                        'Get net bill amt:' || p_bill_id || ' ' ||
                                        sqlerrm);
        end;

        return(l_net_bill_amt);
    end;

    function get_net_bill_amt2(p_bill_id in varchar2) return number is
        l_net_bill_amt number;
    begin
        begin
            select sum(cur_amt)
            into   l_net_bill_amt
            from   ci_bill_sa bsa, ci_sa sa, ci_sa_type sat
            where  bsa.sa_id = sa.sa_id
            and    sa.sa_type_cd = sat.sa_type_cd
            and    (trim(sat.debt_cl_cd) <> 'DEP' or
                  trim(sa.sa_type_cd) = 'D-BILL')
            and    bsa.bill_id = p_bill_id;
        exception
            when others then
                log_error('Getting net billed amount.',
                          sqlerrm,
                          null,
                          null,
                          p_bill_id,
                          null,
                          null);
        end;

        return(l_net_bill_amt);
    end;

    function get_net_bill_amt3(p_bill_id in varchar2) return number is
        l_net_bill_amt number;
    begin
        begin
            select sum(cur_amt)
            into   l_net_bill_amt
            from   ci_bill_sa bsa, ci_sa sa, ci_sa_type sat
            where  bsa.sa_id = sa.sa_id
            and    sa.sa_type_cd = sat.sa_type_cd
            and    trim(sat.debt_cl_cd) <> 'DEP'
            and    bsa.bill_id = p_bill_id;
        exception
            when others then
                log_error('Getting net billed amount3.',
                          sqlerrm,
                          null,
                          null,
                          p_bill_id,
                          null,
                          null);
        end;

        return(l_net_bill_amt);
    end;

    function get_overdue_amt(p_bill_id          in varchar2,
                             p_sa_id            in varchar2,
                             p_current_bill_amt in number) return number is
        l_overdue_amt number;
    begin
        begin
            select cur_amt - p_current_bill_amt
            into   l_overdue_amt
            from   ci_bill_sa
            where  bill_id = p_bill_id
            and    sa_id = p_sa_id;
        exception
            when others then
                l_overdue_amt := 0;
        end;

        if l_overdue_amt < 0
        then
            l_overdue_amt := 0;
        end if;

        return(l_overdue_amt);
    end;

    function get_overdue_amt2(p_bill_id in varchar2) return number is
        l_overdue_amt      number;
        l_current_bill_amt number;
        l_net_bill_amt     number;
    begin
        l_net_bill_amt := get_net_bill_amt3(p_bill_id);

        -- get current bill amount for all bill segments under the bill
        begin
            select sum(cur_amt)
            into   l_current_bill_amt
            from   ci_ft ft, ci_sa sa, ci_sa_type sat
            where  sa.sa_id = ft.sa_id
            and    sat.sa_type_cd = sa.sa_type_cd
            and    trim(sat.debt_cl_cd) <> 'DEP'
            and    bill_id = p_bill_id
            and    ft_type_flg not in ('PS', 'PX');
        exception
            when others then
                l_overdue_amt := 0;
        end;

        l_overdue_amt := l_net_bill_amt - l_current_bill_amt;

        return(l_overdue_amt);
    end;

    function get_overdue_bill_count(p_sa_id       in varchar2,
                                    p_bill_date   in date,
                                    p_overdue_amt in number) return number is
        l_overdue_bill_count number := 1;
        l_bill_id            varchar2(12) := '0';
        l_overdue_amt        number := p_overdue_amt;
    begin
        for r in (select *
                  from   (select ft_type_flg,
                                 cur_amt,
                                 ars_dt,
                                 cre_dttm,
                                 bill_id,
                                 sum(cur_amt) over(partition by sa_id order by ars_dt, cre_dttm) bal
                          from   ci_ft
                          where  sa_id = p_sa_id
                          and    cur_amt <> 0
                          and    ars_dt < p_bill_date
                          order  by ars_dt, cre_dttm)
                  order  by ars_dt desc, cre_dttm desc)
        loop
            if r.ft_type_flg = 'BS' and p_overdue_amt <> r.bal
            then
                l_overdue_bill_count := l_overdue_bill_count + 1;
            end if;

            if p_overdue_amt = r.bal
            then
                exit;
            end if;
        end loop;

        return(l_overdue_bill_count);
    end;

    function get_overdue_bill_cnt(p_sa_id       in varchar2,
                                  p_bill_date   in date,
                                  p_overdue_amt in number) return number as
        -- just select up to 10 bill segments
        -- assumption is customer would have been disconnected after more
        -- than 10 overdue bills
        cursor ft_cur is
            select *
            from   (select ars_dt, sum(ft.cur_amt) cur_amt
                    from   ci_ft ft
                    where  sa_id = p_sa_id
                    and    ars_dt < p_bill_date
                    and    ft_type_flg in ('BS', 'BX')
                    group  by ars_dt
                    order  by ars_dt desc)
            where  rownum <= 10;

        type ft_tab_type is table of ft_cur%rowtype index by binary_integer;

        l_ft  ft_tab_type;
        l_row pls_integer;

        l_ctr  number(10);
        l_prev number(14, 2);
    begin
        l_ctr := 0;
        l_prev := p_overdue_amt;

        open ft_cur;

        loop
            fetch ft_cur bulk collect
                into l_ft;

            l_row := l_ft.first;

            while (l_row is not null)
            loop
                l_ctr := l_ctr + 1;
                l_prev := l_prev - l_ft(l_row).cur_amt;

                if (l_prev <= 0)
                then
                    exit;
                end if;

                l_row := l_ft.next(l_row);
            end loop;

            if (l_prev <= 0)
            then
                exit;
            end if;

            exit when ft_cur%notfound;
        end loop;

        close ft_cur;

        if l_ctr > 1
        then
            l_ctr := l_ctr - 1;
        end if;

        return(l_ctr);
    end;

    function get_bill_message(p_bill_id in varchar2) return varchar2 is
        l_bill_message ci_bill_msgs.bill_msg_cd%type;

        cursor bill_msg_cur is
            select bms.bill_msg_cd
            from   ci_bill_msgs bms, ci_bill_msg bm
            where  bms.bill_msg_cd = bm.bill_msg_cd
            and    bms.bill_id = p_bill_id
            order  by bm.msg_priority_flg desc, bms.bill_msg_cd;
    begin
        open bill_msg_cur;

        fetch bill_msg_cur
            into l_bill_message;

        close bill_msg_cur;

        return(l_bill_message);
    end;

    function get_pole_no(p_sp_id in varchar2) return varchar2 is
        l_pole_no varchar2(20);
    begin
        begin
            select max(geo_val)
            into   l_pole_no
            from   ci_sp_geo spg
            where  spg.sp_id = p_sp_id
            and    spg.geo_type_cd like 'POLENO%';
        exception
            when others then
                l_pole_no := null;
        end;

        return l_pole_no;
    end;

    procedure old_insert_meter_details(p_tran_no in number,
                                       p_bill_id in varchar2,
                                       p_sa_id   in varchar2,
                                       p_bill_dt in date) is
        l_md            bp_meter_details%rowtype;
        l_rownum        number := 0;
        l_curr_badge_no bp_meter_details.badge_no%type;
        l_unmetered_sa  boolean := true;
    begin
        l_md.meter_count := 0;

        -- loop through all the data in the ci_bseg_read
        for r in (select m.badge_nbr,
                         m.serial_nbr,
                         dense_rank() over(order by m.badge_nbr) meter_count,
                         br.reg_const multiplier,
                         trunc(br.start_read_dttm) prev_reading_date,
                         trunc(br.end_read_dttm) curr_reading_date,
                         br.start_reg_reading prev_rdg,
                         br.end_reg_reading curr_rdg,
                         br.msr_qty reg_cons,
                         br.sp_id,
                         br.final_uom_cd uom
                  from   ci_bseg bs,
                         ci_bseg_read br,
                         ci_reg_read rr,
                         ci_reg r,
                         ci_mtr m
                  where  bs.bseg_id = br.bseg_id
                  and    br.start_reg_read_id = rr.reg_read_id
                  and    rr.reg_id = r.reg_id
                  and    m.mtr_id = r.mtr_id
                  and    bs.bseg_stat_flg in ('50', '70')
                  and    bs.bill_id = p_bill_id
                  and    bs.sa_id = p_sa_id
                  and    br.usage_flg = '+'
                  order  by br.start_read_dttm desc)
        loop
            l_unmetered_sa := false;

            if r.uom = 'KWH'
            then
                -- get pole no from ci_sp_geo
                l_md.pole_no := get_pole_no(r.sp_id);

                -- get connected load
                l_md.conn_load := get_bill_sq(p_bill_id,
                                              p_sa_id,
                                              'BILLCNLD',
                                              'W');

                if l_md.conn_load is null
                then
                    l_md.conn_load := get_bill_sq(p_bill_id,
                                                  p_sa_id,
                                                  'CONNLOAD',
                                                  'W');
                end if;

                begin
                    insert into bp_meter_details
                        (tran_no,
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
                         reg_kwhr_cons)
                    values
                        (p_tran_no,
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
                         r.reg_cons);
                exception
                    when dup_val_on_index then
                        begin
                            update bp_meter_details
                            set    pole_no           = l_md.pole_no,
                                   conn_load         = l_md.conn_load,
                                   multiplier        = r.multiplier,
                                   prev_reading_date = r.prev_reading_date,
                                   curr_reading_date = r.curr_reading_date,
                                   prev_kwhr_rdg     = r.prev_rdg,
                                   curr_kwhr_rdg     = r.curr_rdg,
                                   reg_kwhr_cons     = r.reg_cons
                            where  tran_no = p_tran_no
                            and    meter_count = r.meter_count
                            and    badge_no = r.badge_nbr;
                        end;
                    when others then
                        dbms_application_info.set_action('Error Encountered.');
                        raise_application_error(-20100, sqlerrm);
                end;
            end if;

            if r.uom = 'KW'
            then
                -- get pole no from ci_sp_geo
                l_md.pole_no := get_pole_no(r.sp_id);

                l_md.meter_count := l_md.meter_count + 1;

                begin
                    insert into bp_meter_details
                        (tran_no,
                         meter_count,
                         badge_no,
                         serial_no,
                         pole_no,
                         multiplier,
                         prev_reading_date,
                         curr_reading_date,
                         prev_demand_rdg,
                         curr_demand_rdg,
                         reg_demand_cons)
                    values
                        (p_tran_no,
                         r.meter_count,
                         r.badge_nbr,
                         r.serial_nbr,
                         l_md.pole_no,
                         r.multiplier,
                         r.prev_reading_date,
                         r.curr_reading_date,
                         r.prev_rdg,
                         r.curr_rdg,
                         r.reg_cons);
                exception
                    when dup_val_on_index then
                        begin
                            update bp_meter_details
                            set    pole_no           = l_md.pole_no,
                                   multiplier        = r.multiplier,
                                   prev_reading_date = r.prev_reading_date,
                                   curr_reading_date = r.curr_reading_date,
                                   prev_demand_rdg   = r.prev_rdg,
                                   curr_demand_rdg   = r.curr_rdg,
                                   reg_demand_cons   = r.reg_cons
                            where  tran_no = p_tran_no
                            and    meter_count = r.meter_count
                            and    badge_no = r.badge_nbr;
                        end;
                    when others then
                        dbms_application_info.set_action('Error Encountered.');
                        raise_application_error(-20110, sqlerrm);
                end;
            end if;

            if r.uom = 'KVAR'
            then
                -- get pole no from ci_sp_geo
                l_md.pole_no := get_pole_no(r.sp_id);

                begin
                    insert into bp_meter_details
                        (tran_no,
                         meter_count,
                         badge_no,
                         serial_no,
                         pole_no,
                         multiplier,
                         prev_reading_date,
                         curr_reading_date,
                         prev_kvar_rdg,
                         curr_kvar_rdg,
                         reg_kvar_cons)
                    values
                        (p_tran_no,
                         r.meter_count,
                         r.badge_nbr,
                         r.serial_nbr,
                         l_md.pole_no,
                         r.multiplier,
                         r.prev_reading_date,
                         r.curr_reading_date,
                         r.prev_rdg,
                         r.curr_rdg,
                         r.reg_cons);
                exception
                    when dup_val_on_index then
                        begin
                            update bp_meter_details
                            set    pole_no           = l_md.pole_no,
                                   multiplier        = r.multiplier,
                                   prev_reading_date = r.prev_reading_date,
                                   curr_reading_date = r.curr_reading_date,
                                   prev_kvar_rdg     = r.prev_rdg,
                                   curr_kvar_rdg     = r.curr_rdg,
                                   reg_kvar_cons     = r.reg_cons
                            where  tran_no = p_tran_no
                            and    meter_count = r.meter_count
                            and    badge_no = r.badge_nbr;
                        end;
                    when others then
                        dbms_application_info.set_action('Error Encountered.');
                        raise_application_error(-20120, sqlerrm);
                end;
            end if;
        end loop;

        -- if no meter data is found from the bseg_read
        -- assume s.a. is unmetered, so insert dummy meter data
        if l_unmetered_sa
        then
            l_md.meter_count := 1;
            l_md.badge_no := 'UNMETERED';
            l_md.prev_reading_date := last_day(add_months(p_bill_dt, -1));
            l_md.curr_reading_date := last_day(p_bill_dt);
            l_md.conn_load := get_bill_sq(p_bill_id, p_sa_id, 'BILLW', 'W');
            l_md.prev_kwhr_rdg := 0;
            l_md.curr_kwhr_rdg := 0;

            begin
                insert into bp_meter_details
                    (tran_no,
                     meter_count,
                     badge_no,
                     conn_load,
                     prev_reading_date,
                     curr_reading_date,
                     prev_kwhr_rdg,
                     curr_kwhr_rdg)
                values
                    (p_tran_no,
                     l_md.meter_count,
                     l_md.badge_no,
                     l_md.conn_load,
                     l_md.prev_reading_date,
                     l_md.curr_reading_date,
                     l_md.prev_kwhr_rdg,
                     l_md.curr_kwhr_rdg);
            exception
                when others then
                    dbms_application_info.set_action('Error Encountered.');
                    raise_application_error(-20121, sqlerrm);
            end;
        end if;
    end old_insert_meter_details;

    /*procedure insert_meter_details(p_tran_no in number,
                                   p_bill_id in varchar2,
                                   p_sa_id in varchar2,
                                   p_bill_dt in date) is
        l_md bp_meter_details%rowtype;
        l_rownum number := 0;
        l_curr_badge_no bp_meter_details.badge_no%type;
        l_unmetered_sa boolean := true;
        l_bseg_id ci_bseg.bseg_id%type;
    begin
        l_md.meter_count := 0;

        select bseg_id
        into   l_bseg_id
        from   ci_bseg
        where  bill_id = p_bill_id
        and    sa_id = p_sa_id
        and    bseg_stat_flg = '50';

        -- loop through all the data in the ci_bseg_read
        for r in (select badgenumber badge_nbr,
                         serialnumber serial_nbr,
                         dense_rank() over(order by badgenumber) meter_count,
                         constant multiplier,
                         min(to_date(startreaddatetime,
                                     'YYYY-MM-DD-HH24.MI.SS')) prev_reading_date,
                         max(to_date(endreaddatetime,
                                     'YYYY-MM-DD-HH24.MI.SS')) curr_reading_date,
                         min(to_number(startreading)) prev_rdg,
                         max(to_number(endreading)) curr_rdg,
                         sum(to_number(measuredqty)) reg_cons,
                         spid sp_id,
                         finaluom uom
                  from   table(cm_bill_usage_pkg.read(cast(l_bseg_id as
                                                               char(12)))) bill
                  where  sphowtouse = '+'
                  group  by badgenumber,
                            serialnumber,
                            constant,
                            spid,
                            finaluom
                  order  by to_date(min(startreaddatetime),
                                    'YYYY-MM-DD-HH24.MI.SS') desc)
        loop
            l_unmetered_sa := false;

            if r.uom = 'KWH'
            then
                -- get pole no from ci_sp_geo
                l_md.pole_no := get_pole_no(r.sp_id);

                -- get connected load
                l_md.conn_load := get_bill_sq(p_bill_id,
                                              p_sa_id,
                                              'BILLCNLD',
                                              'W');

                if l_md.conn_load is null
                then
                    l_md.conn_load := get_bill_sq(p_bill_id,
                                                  p_sa_id,
                                                  'CONNLOAD',
                                                  'W');
                end if;

                begin
                    insert into bp_meter_details
                        (tran_no,
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
                         reg_kwhr_cons)
                    values
                        (p_tran_no,
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
                         r.reg_cons);
                exception
                    when dup_val_on_index then
                        begin
                            update bp_meter_details
                            set    pole_no = l_md.pole_no,
                                   conn_load = l_md.conn_load,
                                   multiplier = r.multiplier,
                                   prev_reading_date = r.prev_reading_date,
                                   curr_reading_date = r.curr_reading_date,
                                   prev_kwhr_rdg = r.prev_rdg,
                                   curr_kwhr_rdg = r.curr_rdg,
                                   reg_kwhr_cons = r.reg_cons
                            where  tran_no = p_tran_no
                            and    meter_count = r.meter_count
                            and    badge_no = r.badge_nbr;
                        end;
                    when others then
                        dbms_application_info.set_action('Error Encountered.');
                        raise_application_error(-20100, sqlerrm);
                end;
            end if;

            if r.uom = 'KW'
            then
                -- get pole no from ci_sp_geo
                l_md.pole_no := get_pole_no(r.sp_id);

                l_md.meter_count := l_md.meter_count + 1;

                begin
                    insert into bp_meter_details
                        (tran_no,
                         meter_count,
                         badge_no,
                         serial_no,
                         pole_no,
                         multiplier,
                         prev_reading_date,
                         curr_reading_date,
                         prev_demand_rdg,
                         curr_demand_rdg,
                         reg_demand_cons)
                    values
                        (p_tran_no,
                         r.meter_count,
                         r.badge_nbr,
                         r.serial_nbr,
                         l_md.pole_no,
                         r.multiplier,
                         r.prev_reading_date,
                         r.curr_reading_date,
                         r.prev_rdg,
                         r.curr_rdg,
                         r.reg_cons);
                exception
                    when dup_val_on_index then
                        begin
                            update bp_meter_details
                            set    pole_no = l_md.pole_no,
                                   multiplier = r.multiplier,
                                   prev_reading_date = r.prev_reading_date,
                                   curr_reading_date = r.curr_reading_date,
                                   prev_demand_rdg = r.prev_rdg,
                                   curr_demand_rdg = r.curr_rdg,
                                   reg_demand_cons = r.reg_cons
                            where  tran_no = p_tran_no
                            and    meter_count = r.meter_count
                            and    badge_no = r.badge_nbr;
                        end;
                    when others then
                        dbms_application_info.set_action('Error Encountered.');
                        raise_application_error(-20110, sqlerrm);
                end;
            end if;

            if r.uom = 'KVAR'
            then
                -- get pole no from ci_sp_geo
                l_md.pole_no := get_pole_no(r.sp_id);

                begin
                    insert into bp_meter_details
                        (tran_no,
                         meter_count,
                         badge_no,
                         serial_no,
                         pole_no,
                         multiplier,
                         prev_reading_date,
                         curr_reading_date,
                         prev_kvar_rdg,
                         curr_kvar_rdg,
                         reg_kvar_cons)
                    values
                        (p_tran_no,
                         r.meter_count,
                         r.badge_nbr,
                         r.serial_nbr,
                         l_md.pole_no,
                         r.multiplier,
                         r.prev_reading_date,
                         r.curr_reading_date,
                         r.prev_rdg,
                         r.curr_rdg,
                         r.reg_cons);
                exception
                    when dup_val_on_index then
                        begin
                            update bp_meter_details
                            set    pole_no = l_md.pole_no,
                                   multiplier = r.multiplier,
                                   prev_reading_date = r.prev_reading_date,
                                   curr_reading_date = r.curr_reading_date,
                                   prev_kvar_rdg = r.prev_rdg,
                                   curr_kvar_rdg = r.curr_rdg,
                                   reg_kvar_cons = r.reg_cons
                            where  tran_no = p_tran_no
                            and    meter_count = r.meter_count
                            and    badge_no = r.badge_nbr;
                        end;
                    when others then
                        dbms_application_info.set_action('Error Encountered.');
                        raise_application_error(-20120, sqlerrm);
                end;
            end if;
        end loop;

        -- if no meter data is found from the bseg_read
        -- assume s.a. is unmetered, so insert dummy meter data
        if l_unmetered_sa
        then
            l_md.meter_count := 1;
            l_md.badge_no := 'UNMETERED';
            l_md.prev_reading_date := last_day(add_months(p_bill_dt, -1));
            l_md.curr_reading_date := last_day(p_bill_dt);
            l_md.conn_load := get_bill_sq(p_bill_id, p_sa_id, 'BILLW', 'W');
            l_md.prev_kwhr_rdg := 0;
            l_md.curr_kwhr_rdg := 0;

            begin
                insert into bp_meter_details
                    (tran_no,
                     meter_count,
                     badge_no,
                     conn_load,
                     prev_reading_date,
                     curr_reading_date,
                     prev_kwhr_rdg,
                     curr_kwhr_rdg)
                values
                    (p_tran_no,
                     l_md.meter_count,
                     l_md.badge_no,
                     l_md.conn_load,
                     l_md.prev_reading_date,
                     l_md.curr_reading_date,
                     l_md.prev_kwhr_rdg,
                     l_md.curr_kwhr_rdg);
            exception
                when others then
                    dbms_application_info.set_action('Error Encountered.');
                    raise_application_error(-20121, sqlerrm);
            end;
        end if;
    end;*/

    procedure insert_consumption_hist(p_tran_no   in number,
                                      p_sa_id     in varchar2,
                                      p_bill_date in date) is
    begin
        begin
            insert into bp_consumption_hist
                (tran_no, rdg_date, consumption)
                (select p_tran_no, trunc(rdg_date), sum(consumption)
                 from   (select distinct bs.end_dt rdg_date,
                                         bsq.bill_sq consumption
                         from   ci_bseg bs, ci_bseg_sq bsq
                         where  bs.bseg_id = bsq.bseg_id
                         and    bsq.sqi_cd = rpad('BILLKWH', 8)
                         and    bs.bseg_stat_flg in ('50', '70')
                         and    bs.sa_id = p_sa_id
                         and    bs.end_dt <= p_bill_date
                         order  by bs.end_dt desc)
                 where  rownum <= 13
                 group  by trunc(rdg_date));
        exception
            when others then
                dbms_application_info.set_action('Error Encountered.');
                raise_application_error(-20130, sqlerrm);
        end;
    end;

    procedure add_detail_line(p_tran_no     in number,
                              p_line_code   in varchar2,
                              p_line_rate   in varchar2,
                              p_line_amount in number) is
    begin
        begin
            insert into bp_details
                (tran_no, line_code, line_rate, line_amount)
            values
                (p_tran_no, p_line_code, p_line_rate, p_line_amount);
        exception
            when dup_val_on_index then
                begin
                    update bp_details
                    set    line_amount = line_amount + p_line_amount
                    where  tran_no = p_tran_no
                    and    line_code = p_line_code;
                exception
                    when others then
                        dbms_application_info.set_action('Error Encountered.');
                        raise_application_error(-20136, sqlerrm);
                end;
            when others then
                dbms_application_info.set_action('Error Encountered.');
                raise_application_error(-20135, sqlerrm);
        end;
    end;

    function get_line_code(p_descr_on_bill in varchar2,
                           p_sqi_code      in varchar2,
                           p_bill_id       in varchar2 -- used for error reporting only
                           ) return varchar2 is
        l_line_code bp_detail_codes.code%type;
    begin
        begin
            select code
            into   l_line_code
            from   bp_detail_codes
            where  p_descr_on_bill like
                   nvl(ccnb_descr_on_bill, '00') || '%'
            and    nvl(ccnb_sqi_cd, '0') = nvl(p_sqi_code, '0');
        exception
            when too_many_rows then
                log_error(p_descr_on_bill || ' ' || p_sqi_code || ' ' ||
                          p_bill_id,
                          sqlerrm,
                          'More than one row found.',
                          null,
                          null,
                          null,
                          null);
                raise_application_error(-20150,
                                        'More than 1 row found for ' ||
                                        p_descr_on_bill || ' ' ||
                                        p_sqi_code || ' ' || p_bill_id);
            when no_data_found then
                log_error(p_descr_on_bill || ' ' || p_sqi_code || ' ' ||
                          p_bill_id,
                          sqlerrm,
                          'Calc line not found in bp_detail_codes',
                          null,
                          null,
                          null,
                          null);
                raise_application_error(-20155,
                                        p_descr_on_bill || ' ' ||
                                        p_sqi_code || ' ' || p_bill_id ||
                                        ' is not found.');
            when others then
                dbms_application_info.set_action('Error Encountered.');
                raise_application_error(-20160, sqlerrm);
        end;

        return(l_line_code);
    end;

    function get_line_rate(p_line_code     in varchar2,
                           p_descr_on_bill in varchar2,
                           p_uom_cd        in varchar2) return varchar2 is
        l_line_rate varchar2(100);
        l_uom_cd    varchar2(100);
        l_offset    number;
    begin
        begin
            select regular_desc
            into   l_uom_cd
            from   bp_detail_codes
            where  code = p_line_code;
        exception
            when others then
                dbms_application_info.set_action('Error Encountered.');
                raise_application_error(-20170, sqlerrm);
        end;

        l_offset := instr(p_descr_on_bill, '(Rate:P');

        if l_offset > 0
        then
            l_line_rate := replace(substr(p_descr_on_bill, l_offset + 7),
                                   ')',
                                   null) || '/' || l_uom_cd;
        end if;

        return(l_line_rate);
    end;

    function get_par_kwh(p_bill_id in varchar2) return number as
        l_calc_amt number(15, 2);
    begin
        begin
            select calc_amt
            into   l_calc_amt
            from   ci_bseg_calc_ln calc, ci_bseg bseg
            where  calc.bseg_id = bseg.bseg_id
            and    bseg.bseg_stat_flg in ('50', '70') -->> v1.5.1
            and    bill_id = p_bill_id
            and    calc.descr_on_bill like 'FCPO: PAR%';
        exception
            when no_data_found then
                l_calc_amt := 0;
            when others then
                log_error('GET_PAR_KWH ' || p_bill_id,
                          sqlerrm,
                          'Error in retrieving PAR amount',
                          null,
                          null,
                          null,
                          null);

                l_calc_amt := 0;
        end;

        return l_calc_amt;
    end;

    function get_par_month(p_sa_id in varchar2, p_bill_month in date)
        return date as
        l_date date;
    begin
        begin
            select max(end_dt)
            into   l_date
            from   (select trunc(bseg.end_dt, 'MM') end_dt,
                           acct.bill_cyc_cd,
                           dense_rank() over(order by trunc(bseg.end_dt, 'MM') desc) seq
                    from   ci_bseg bseg, ci_bill bill, ci_acct acct
                    where  bseg.sa_id = p_sa_id
                          --and    bseg.bseg_stat_flg = 50
                    and    bseg.bseg_stat_flg in ('50', '70') -->> v1.5.1
                    and    trunc(bseg.end_dt, 'MM') <
                           trunc(p_bill_month, 'MM')
                    and    bseg.bill_id = bill.bill_id
                    and    bill.acct_id = acct.acct_id
                    and    acct.bill_cyc_cd in ('BC01',
                                                'BC02',
                                                'BC03',
                                                'BC04',
                                                'BC05',
                                                'BC06',
                                                'BC07',
                                                'BC08',
                                                'BC09',
                                                'BC10',
                                                'BC11',
                                                'BC12',
                                                'BC13',
                                                'BC14',
                                                'BC15',
                                                'BC16',
                                                'BC17',
                                                'BC18',
                                                'BC19',
                                                'BC20',
                                                'BC21',
                                                'BC22',
                                                'BC23',
                                                'BC24',
                                                'BC25')) main
            where  seq = 2;
        exception
            when others then
                log_error('GET_PAR_MONTH SA ID:' || p_sa_id ||
                          ' Bill Month:' || p_bill_month,
                          sqlerrm,
                          'Error in retrieving PAR amount',
                          null,
                          null,
                          null,
                          null);
        end;

        return l_date;
    end;

    procedure insert_detail_4par(p_tran_no in number,
                                 p_bill_id in varchar2,
                                 p_sa_id   in varchar2) as
        cursor calc_ln_cur is
            select cl.uom_cd,
                   cl.tou_cd,
                   cl.calc_amt,
                   cl.base_amt,
                   cl.sqi_cd,
                   cl.descr_on_bill
            from   ci_bseg_calc_ln cl, ci_bseg_calc bc, ci_bseg bs
            where  bs.bseg_id = bc.bseg_id
            and    bc.bseg_id = cl.bseg_id
            and    bc.header_seq = cl.header_seq
            and    bc.header_seq = 1
            and    bs.bseg_stat_flg in ('50', '70')
            and    bs.bill_id = p_bill_id
            and    bs.sa_id = p_sa_id
            and    prt_sw = 'Y'
            and    cl.descr_on_bill like '%Power Act Reduction%'
            order  by rc_seq;

        type cl_tab_type is table of calc_ln_cur%rowtype index by binary_integer;

        l_cl  cl_tab_type;
        l_row pls_integer;

        l_bpd  bp_details%rowtype;
        l_rate number;
    begin
        open calc_ln_cur;

        loop
            fetch calc_ln_cur bulk collect
                into l_cl limit 50;

            l_row := l_cl.first;

            while (l_row is not null)
            loop
                l_bpd.line_code := get_line_code(l_cl(l_row).descr_on_bill,
                                                 trim(l_cl(l_row).sqi_cd),
                                                 p_bill_id);

                --l_rate := replace(replace(replace(replace(l_cl(l_row).descr_on_bill,'Power Act Reduction (Rate:'),'%'),')'),'P');
                begin
                    l_rate := replace(replace(replace(replace(l_cl(l_row).descr_on_bill,
                                                              'Power Act Reduction (Rate:'),
                                                      '%'),
                                              ')'),
                                      'P');
                exception
                    when others then
                        l_rate := replace(replace(replace(replace(l_cl(l_row).descr_on_bill,
                                                                  'Power Act Reduction 2 (Rate:'),
                                                          '%'),
                                                  ')'),
                                          'P');
                end;

                if instr(l_cl(l_row).descr_on_bill, '%') > 1
                then
                    l_rate := l_rate / 100;
                end if;

                l_bpd.line_rate := to_char(l_rate, 'fm990.099999999') ||
                                   '/kWh';

                add_detail_line(p_tran_no,
                                l_bpd.line_code,
                                l_bpd.line_rate,
                                l_cl(l_row).calc_amt);

                l_row := l_cl.next(l_row);
            end loop;

            exit when calc_ln_cur%notfound;
        end loop;
    end insert_detail_4par;

    procedure adjust_uc_spug(p_tran_no in number, p_bill_id in varchar2)

        --Version History
        /*--------------------------------------------------------
        v1.4.0 by gperater on January 10, 2024
               remarks : minimize the decimal places of line NPC-SPUG to 4 places

         v1.3.9.6 by rreston on June 08, 2023
        Remarks : revised existing procedure in relation to CM 1678: VECO New Transmission Charge Allocation / UCME true up


        v1.3.9.4 by jtan on Dec 15, 2022
        Remarks : as per SDP # 200204

        v1.3.9.3 by GMEPIEZA on September  12, 2022
        Remarks : added a new procedure to get the line_rate and be displayed on the
                  bill presentment UC-ME-SPUG

        */
        --------------------------------------------------------

     as
        l_uc_total  number;
        l_bseg_id   char(12);
        l_uc_descr  varchar2(30);
        l_line_rate varchar2(300);
    begin

        begin
            delete from bp_details
            where  tran_no = p_tran_no
            and    line_code in ('UC-ME-SPUG');

            begin
                select cl.calc_amt, cl.bseg_id, 'UC_ME_SPUG'
                into   l_uc_total, l_bseg_id, l_uc_descr
                from   ci_bseg_calc_ln cl, ci_bseg_calc bc, ci_bseg bs
                where  bs.bseg_id = bc.bseg_id
                and    bc.bseg_id = cl.bseg_id
                and    bc.header_seq = cl.header_seq
                and    bs.bseg_stat_flg in ('50', '70')
                and    bs.bill_id = p_bill_id
                and    prt_sw = 'Y'
                and    cl.descr_on_bill =
                       'Universal Charge Missionary Electrification - NPC-SPUG';

            exception
                when no_data_found then
                    null;

            end;

        end;

        declare
            l_descr_on_bill  varchar2(80);
            l_sqi_cd         char(8);
            l_offset         number;
            l_rate           number;
            l_descr_on_bill2 varchar2(80);
            l_sqi_cd2        char(8);
            l_rate2          number;
            l_calc_amt2      number;
            l_descr_on_bill3 varchar2(80);
            l_sqi_cd3        char(8);
            l_rate3          number;
            l_descr_on_bill4 varchar2(80);
            l_sqi_cd4        char(8);
            l_rate4          number;
            l_descr_on_bill5 varchar2(80);
            l_sqi_cd5        char(8);
            l_rate5          number;
            l_descr_on_bill6 varchar2(80);
            l_sqi_cd6        char(8);
            l_rate6          number;
            l_total_rate     number;
            l_final_uom      varchar2(10);
        begin
            -- uc missionary electrification
            begin
                select descr_on_bill, sqi_cd
                into   l_descr_on_bill, l_sqi_cd
                from   ci_bseg_calc_ln
                where  bseg_id = l_bseg_id
                and    dst_id like 'DV-UME    ' || '%';
                --  and    descr_on_bill like
                --'Universal Charge - Missionary Electrification' || '%';

                l_offset := instr(l_descr_on_bill, '(Rate:P');

                if l_offset > 0
                then
                    l_rate := to_number(replace(substr(l_descr_on_bill,
                                                       l_offset + 7),
                                                ')',
                                                null));
                end if;
            exception
                when no_data_found then
                    null;
            end;

            -- uc missionary electrification cash incentive for RE
            begin
                select descr_on_bill, sqi_cd, calc_amt
                into   l_descr_on_bill2, l_sqi_cd2, l_calc_amt2
                from   ci_bseg_calc_ln
                where  bseg_id = l_bseg_id
                and    dst_id like 'DV-UMERE  ' || '%';
                --  and    descr_on_bill like
                --       'Universal Charge-Missionary Electrification Cash Incentive for RE' || '%';

                l_offset := instr(l_descr_on_bill2, '(Rate:P');

                if l_offset > 0
                then
                    l_rate2 := to_number(replace(substr(l_descr_on_bill2,
                                                        l_offset + 7),
                                                 ')',
                                                 null));
                end if;
            exception
                when no_data_found then
                    null;
            end;

            --Universal Charge - Missionary Electrification 3 (Rate:%R)
            begin
                select descr_on_bill, sqi_cd
                into   l_descr_on_bill3, l_sqi_cd3
                from   ci_bseg_calc_ln
                where  bseg_id = l_bseg_id
                and    dst_id like 'DV-UME3   ' || '%';
                --  and    descr_on_bill like
                --    'Universal Charge-Missionary Electrification 3' || '%';

                l_offset := instr(l_descr_on_bill3, '(Rate:P');

                if l_offset > 0
                then
                    l_rate3 := to_number(replace(substr(l_descr_on_bill3,
                                                        l_offset + 7),
                                                 ')',
                                                 null));
                end if;
            exception
                when no_data_found then
                    null;
            end;

            --Universal Charge-Missionary Electrification True Up (Rate:P0.004563) -->> gmepieza 09/06/2022
            begin
                select descr_on_bill, sqi_cd
                into   l_descr_on_bill4, l_sqi_cd4
                from   ci_bseg_calc_ln
                where  bseg_id = l_bseg_id
                and    dst_id like 'DV-UCMETU ' || '%';
                --and    descr_on_bill like
                --'Universal Charge-Missionary Electrification True Up' || '%';

                l_offset := instr(l_descr_on_bill4, '(Rate:P');

                if l_offset > 0
                then
                    l_rate4 := to_number(replace(substr(l_descr_on_bill4,
                                                        l_offset + 7),
                                                 ')',
                                                 null));
                end if;
            exception
                when no_data_found then
                    null;
            end;

            --universal charge missionary true up 2013
            begin
                select descr_on_bill, sqi_cd
                into   l_descr_on_bill5, l_sqi_cd5
                from   ci_bseg_calc_ln
                where  bseg_id = l_bseg_id
                and    dst_id like 'DV-UCMETU2' || '%';
                --and    descr_on_bill like
                --'Universal Charge-Missionary Electrification True Up' || '%';

                l_offset := instr(l_descr_on_bill5, '(Rate:P');

                if l_offset > 0
                then
                    l_rate5 := to_number(replace(substr(l_descr_on_bill5,
                                                        l_offset + 7),
                                                 ')',
                                                 null));
                end if;
            exception
                when no_data_found then
                    null;
            end;

            --universal charge missionary true up 2014
            begin
                select descr_on_bill, sqi_cd
                into   l_descr_on_bill6, l_sqi_cd6
                from   ci_bseg_calc_ln
                where  bseg_id = l_bseg_id
                and    dst_id like 'DV-UCMETU3' || '%';
                --and    descr_on_bill like
                --'Universal Charge-Missionary Electrification True Up' || '%';

                l_offset := instr(l_descr_on_bill6, '(Rate:P');

                if l_offset > 0
                then
                    l_rate6 := to_number(replace(substr(l_descr_on_bill6,
                                                        l_offset + 7),
                                                 ')',
                                                 null));
                end if;
            exception
                when no_data_found then
                    null;
            end;

            if trim(l_sqi_cd) = 'BILLKWH'
            then
                l_final_uom := 'kWh';
            elsif trim(l_sqi_cd) = 'CMBKWHT'
            then
                l_final_uom := 'kWh';
            elsif trim(l_sqi_cd) = 'FLTKWH'
            then
                l_final_uom := 'kWh';
            elsif trim(l_sqi_cd) = 'BILLW'
            then
                l_final_uom := 'Watt';
            end if;

            declare
                l_total_rate_spug number;
                l_total_rate_red  number;
            begin
                l_total_rate_spug := nvl(l_rate, 0) + nvl(l_rate3, 0) +
                                     nvl(l_rate4, 0) +
                                     nvl(l_rate5, 0) +
                                     nvl(l_rate6, 0);
                l_line_rate := to_char(l_total_rate_spug, 'fm0.0999') || '/' ||
                               l_final_uom;
                add_detail_line(p_tran_no,
                                'UC-ME-SPUG',
                                l_line_rate,
                                l_uc_total);

            end;

        end;
        /*
        declare
            l_rate_sched   varchar2(15);
            l_total_cons   number;
            l_uc_spug      number;
            l_uc_line_rate varchar2(50);
            l_uc_amount    number;
            l_line         number;
        begin
            l_line := 10;
            select rate_schedule --, billed_kwhr_cons
            into   l_rate_sched --, l_total_cons
            from   bp_headers
            where  tran_no = p_tran_no;

            /*l_line := 20;
            select line_amount
            into   l_uc_spug
            from   bp_details
            where  tran_no = p_tran_no
            and    line_code in ('UC-ME-SPUG');

            l_uc_amount := (l_uc_spug / l_total_cons);

            l_uc_amount := round(l_uc_amount, 4);

            --l_uc_line_rate := to_char(l_uc_amount, 'fm9990.0000') || '/kWh';

            if l_rate_sched in ('01-F-11', '01-F-12')
            then
                l_uc_line_rate := to_char(l_uc_amount, 'fm9990.0000') ||
                                  '/Watt';
            else
                l_uc_line_rate := to_char(l_uc_amount, 'fm9990.0000') ||
                                  '/kWh';
            end if;*/
        /*
            if l_rate_sched in ('01-F-11', '01-F-12')
            then
                l_uc_line_rate := '0.064188/Watt';
            else
                l_uc_line_rate := '0.1783/kWh';
            end if;

            update bp_details
            set    line_rate = l_uc_line_rate
            where  tran_no = p_tran_no
            and    line_code in ('UC-ME-SPUG');
        exception
            when no_data_found then
                null;
        end; */

    exception
        when others then
            log_error('ADJUST_UC_SPUG:' || p_bill_id || ' Bill id:' ||
                      p_bill_id,
                      sqlerrm,
                      'Error in Adjusting UC SPUG',
                      null,
                      null,
                      null,
                      null);
    end adjust_uc_spug;

    procedure adjust_uc_mes(p_bill_id in varchar2,
                            p_sa_id   in varchar2,
                            p_tran_no in number) as
        l_uc_total  number;
        l_bseg_id   char(12);
        l_line_rate varchar2(300);
    begin
        begin
            select cl.calc_amt, cl.bseg_id
            into   l_uc_total, l_bseg_id
            from   ci_bseg_calc_ln cl, ci_bseg_calc bc, ci_bseg bs
            where  bs.bseg_id = bc.bseg_id
            and    bc.bseg_id = cl.bseg_id
            and    bc.header_seq = cl.header_seq
            and    bs.bseg_stat_flg in ('50', '70')
            and    bs.bill_id = p_bill_id
            and    bs.sa_id = p_sa_id
            and    prt_sw = 'Y'
            and    cl.descr_on_bill = 'UC-ME Total';

            declare
                l_descr_on_bill  varchar2(80);
                l_sqi_cd         char(8);
                l_offset         number;
                l_rate           number;
                l_descr_on_bill2 varchar2(80);
                l_sqi_cd2        char(8);
                l_rate2          number;
                l_descr_on_bill3 varchar2(80);
                l_sqi_cd3        char(8);
                l_rate3          number;
                l_total_rate     number;
                l_final_uom      varchar2(10);
            begin

                -- uc missionary electrification
                begin
                    select descr_on_bill, sqi_cd
                    into   l_descr_on_bill, l_sqi_cd
                    from   ci_bseg_calc_ln
                    where  bseg_id = l_bseg_id
                    and    descr_on_bill like
                           'Universal Charge % Missionary Electrification' || '%';

                    l_offset := instr(l_descr_on_bill, '(Rate:P');

                    if l_offset > 0
                    then
                        l_rate := to_number(replace(replace(substr(l_descr_on_bill,
                                                                   l_offset + 7),
                                                            ')',
                                                            null),
                                                    '/KWH',
                                                    null));
                    end if;
                exception
                    when no_data_found then
                        null;
                end;

                -- uc missionary electrification cash incentive for RD
                begin
                    select descr_on_bill, sqi_cd
                    into   l_descr_on_bill2, l_sqi_cd2
                    from   ci_bseg_calc_ln
                    where  bseg_id = l_bseg_id
                    and    descr_on_bill like
                           'Universal Charge-Missionary Electrification Cash Incentive for RE' || '%';

                    l_offset := instr(l_descr_on_bill2, '(Rate:P');

                    if l_offset > 0
                    then
                        l_rate2 := to_number(replace(replace(substr(l_descr_on_bill2,
                                                                    l_offset + 7),
                                                             ')',
                                                             null),
                                                     '/KWH',
                                                     null));
                    end if;
                exception
                    when no_data_found then
                        null;
                end;

                --Universal Charge-Missionary Electrification 3 (Rate:P0.0381)
                begin
                    select descr_on_bill, sqi_cd
                    into   l_descr_on_bill3, l_sqi_cd3
                    from   ci_bseg_calc_ln
                    where  bseg_id = l_bseg_id
                    and    descr_on_bill like
                           'Universal Charge-Missionary Electrification 3' || '%';

                    l_offset := instr(l_descr_on_bill3, '(Rate:P');

                    if l_offset > 0
                    then
                        l_rate3 := to_number(replace(replace(substr(l_descr_on_bill3,
                                                                    l_offset + 7),
                                                             ')',
                                                             null),
                                                     '/KWH',
                                                     null));
                    end if;
                exception
                    when no_data_found then
                        null;
                end;

                l_total_rate := nvl(l_rate, 0) + nvl(l_rate2, 0) +
                                nvl(l_rate3, 0);

                if trim(l_sqi_cd) = 'BILLKWH'
                then
                    l_final_uom := 'kWh';
                elsif trim(l_sqi_cd) = 'CMBKWHT'
                then
                    l_final_uom := 'kWh';
                elsif trim(l_sqi_cd) = 'FLTKWH'
                then
                    l_final_uom := 'Watt';
                elsif trim(l_sqi_cd) = 'BILLW'
                then
                    l_final_uom := 'Watt';
                end if;

                l_line_rate := to_char(l_total_rate, 'fm0.09999999') || '/' ||
                               l_final_uom;
            end;

            delete from bp_details
            where  tran_no = p_tran_no
            and    line_code in ('UME-KWH-TOU',
                                 'UME-FLT',
                                 'UME-W',
                                 'UME',
                                 'UMERE-W',
                                 'UC-MES',
                                 'UMERE-FLT',
                                 'UMERE-KWH',
                                 'UMERE-KWH-TOU',
                                 'UME-KWH',
                                 'UMERE-FLT3',
                                 'UMERE-KWH3',
                                 'UMERE-KWH-TOU3',
                                 'UMERE-W3',
                                 'UME-RCOA');

            add_detail_line(p_tran_no, 'UC-MES', l_line_rate, l_uc_total);

        exception
            when no_data_found then
                null;
        end;
    exception
        when others then
            log_error('ADJUST_UC_MES SA ID:' || p_sa_id || ' Bill id:' ||
                      p_bill_id,
                      sqlerrm,
                      'Error in Adjusting UC MEs',
                      null,
                      null,
                      null,
                      null);
    end adjust_uc_mes;

    procedure insert_bp_details(p_tran_no in number,
                                p_bill_id in varchar2,
                                p_sa_id   in varchar2) is
        cursor calc_ln_cur is
            select cl.uom_cd,
                   cl.tou_cd,
                   cl.calc_amt,
                   cl.base_amt,
                   cl.sqi_cd,
                   cl.descr_on_bill
            from   ci_bseg_calc_ln cl, ci_bseg_calc bc, ci_bseg bs
            where  bs.bseg_id = bc.bseg_id
            and    bc.bseg_id = cl.bseg_id
            and    bc.header_seq = cl.header_seq
            and    bc.header_seq = 1
            and    bs.bseg_stat_flg in ('50', '70')
            and    bs.bill_id = p_bill_id
            and    bs.sa_id = p_sa_id
            and    prt_sw = 'Y'
            and    (cl.descr_on_bill not like '%Power Act Reduction%' and
                  cl.descr_on_bill not like '%BIR 2306 PPVAT-TVI%')
            order  by rc_seq;

        type cl_tab_type is table of calc_ln_cur%rowtype index by binary_integer;

        l_cl  cl_tab_type;
        l_row pls_integer;

        l_bpd        bp_details%rowtype;
        l_lpc_amount number;
    begin
        open calc_ln_cur;

        loop
            fetch calc_ln_cur bulk collect
                into l_cl limit 50;

            l_row := l_cl.first;

            while (l_row is not null)
            loop
                l_bpd.line_code := get_line_code(l_cl(l_row).descr_on_bill,
                                                 trim(l_cl(l_row).sqi_cd),
                                                 p_bill_id);

                if l_bpd.line_code = 'SLF-D'
                then
                    l_bpd.line_rate := to_char(round(l_cl(l_row).calc_amt / l_cl(l_row).base_amt,
                                                     2),
                                               'fm999,990.999999') ||
                                       ' of ' ||
                                       to_char(l_cl(l_row).base_amt,
                                               'fm999,999,999,990.00');
                else
                    l_bpd.line_rate := get_line_rate(l_bpd.line_code,
                                                     replace(replace(replace(l_cl(l_row).descr_on_bill,
                                                                             '/KWH'),
                                                                     '/KW'),
                                                             '/month'),
                                                     trim(l_cl(l_row).uom_cd));
                end if;

                add_detail_line(p_tran_no,
                                l_bpd.line_code,
                                l_bpd.line_rate,
                                l_cl(l_row).calc_amt);

                l_row := l_cl.next(l_row);
            end loop;

            exit when calc_ln_cur%notfound;
        end loop;

        close calc_ln_cur;

        -- add surcharge / late payment charge
        l_lpc_amount := get_lpc(p_bill_id);

        if l_lpc_amount > 0
        then
            add_detail_line(p_tran_no,
                            'ADJLPC',
                            '0.02 of ' ||
                            to_char(round(l_lpc_amount / 0.02, 2),
                                    'fm999,999,999,990.00'),
                            l_lpc_amount);
        end if;

        -- add detail line for PAR
        insert_detail_4par(p_tran_no, p_bill_id, p_sa_id);

        --UC missionary adjustments
        adjust_uc_mes(p_bill_id, p_sa_id, p_tran_no);

        --UC ME SPUG
        adjust_uc_spug(p_tran_no, p_bill_id); -->> gperater 09/12/2022

        -- add sub totals
        begin
            insert into bp_details
                (tran_no, line_code, line_amount)
                (select bpd.tran_no, bpc.summary_group, sum(line_amount)
                 from   bp_details bpd, bp_detail_codes bpc
                 where  bpd.line_code = bpc.code
                 and    bpd.tran_no = p_tran_no
                 group  by bpd.tran_no, bpc.summary_group);
        end;

        -- add header info
        add_detail_line(p_tran_no, 'PREVAMTSPACER', null, null);
        add_detail_line(p_tran_no, 'CURCHARGES', null, null);
        add_detail_line(p_tran_no, 'vGENCHGHDR', null, null);
        add_detail_line(p_tran_no, 'vDISTREVHDR', null, null);
        add_detail_line(p_tran_no, 'vOTHHDR', null, null);
        add_detail_line(p_tran_no, 'vGOVREVHDR', null, null);
        add_detail_line(p_tran_no, 'vVATHDR', null, null);
        add_detail_line(p_tran_no, 'vUNIVCHGHDR', null, null);
        add_detail_line(p_tran_no, 'NETSPACER', null, null);
    end;

    procedure insert_other_bseg(p_tran_no in number, p_bill_id in varchar2) is
    begin
        begin
            insert into bp_details
                (tran_no, line_code, line_amount)
                (select p_tran_no, trim(sa.sa_type_cd), sum(bc.calc_amt)
                 from   ci_bseg bs,
                        ci_sa sa,
                        ci_sa_type st,
                        ci_bseg_calc bc
                 where  bs.sa_id = sa.sa_id
                 and    st.sa_type_cd = sa.sa_type_cd
                 and    bs.bseg_id = bc.bseg_id
                 and    bs.bseg_stat_flg in ('50', '70') -- Frozen/OK
                 and    st.bill_seg_type_cd in ('RECUR-AS', 'BCHG-DFT')
                 and    bc.header_seq = 1
                 and    bs.bill_id = p_bill_id
                 group  by p_tran_no, sa.sa_type_cd);
        exception
            when others then
                dbms_application_info.set_action('Error Encountered.');
                raise_application_error(-20171,
                                        p_bill_id || ' ' || sqlerrm);
        end;
    end;
    
    --03/06/2024
    procedure insert_bd_bseg(p_tran_no in number, p_bill_id in varchar2) is
    begin
        begin
            insert into bp_details
                (tran_no, line_code, line_amount)
                (select p_tran_no, trim(sa.sa_type_cd), sum(bc.calc_amt)
                 from   ci_bseg bs,
                        ci_sa sa,
                        ci_sa_type st,
                        ci_bseg_calc bc
                 where  bs.sa_id = sa.sa_id
                 and    st.sa_type_cd = sa.sa_type_cd
                 and    bs.bseg_id = bc.bseg_id
                 and    bs.bseg_stat_flg in ('50', '70') -- Frozen/OK
                 and    st.bill_seg_type_cd in ('REC-TATB')
                 and    st.sa_type_cd = 'D-BILL  '
                 and    bc.header_seq = 1
                 and    bs.bill_id = p_bill_id
                 group  by p_tran_no, sa.sa_type_cd);
        exception
            when others then
                dbms_application_info.set_action('Error Encountered.');
                raise_application_error(-20171,
                                        p_bill_id || ' ' || sqlerrm);
        end;
    end;

    function get_other_bseg_amt(p_bill_id in varchar2) return number is
        l_other_bseg_amt number;
    begin
        begin
            select nvl(sum(bc.calc_amt), 0)
            into   l_other_bseg_amt
            from   ci_bseg bs, ci_sa sa, ci_sa_type st, ci_bseg_calc bc
            where  bs.sa_id = sa.sa_id
            and    st.sa_type_cd = sa.sa_type_cd
            and    bs.bseg_id = bc.bseg_id
            and    bs.bseg_stat_flg in ('50', '70') -- Frozen/OK
            and    st.bill_seg_type_cd in ('RECUR-AS', 'BCHG-DFT')
            and    bc.header_seq = 1
            and    bs.bill_id = p_bill_id;
        exception
            when others then
                l_other_bseg_amt := 0;
        end;

        return(l_other_bseg_amt);
    end;

    function get_billing_cycle(p_acct_id in varchar2) return varchar2 as
        l_bc varchar2(4);
    begin
        begin
            select trim(bill_cyc_cd)
            into   l_bc
            from   ci_acct
            where  acct_id = p_acct_id;
        exception
            when no_data_found then
                null;
            when others then
                log_error('BILL CYCLE ' || p_acct_id,
                          sqlerrm,
                          'Error encountered at function GET_BILLING_CYCLE',
                          null,
                          null,
                          null,
                          null);
        end;

        return l_bc;
    end get_billing_cycle;

    procedure insert_adj(p_tran_no  in number,
                         p_bill_id  in varchar2,
                         p_sa_id    in varchar2,
                         p_cmdm_amt in number) is
        l_adj_gsl  number;
        l_cmdm_amt number;
    begin
        l_cmdm_amt := p_cmdm_amt;

        begin
            select nvl(sum(cur_amt), 0) adj_amt
            into   l_adj_gsl
            from   ci_ft
            where  sa_id = p_sa_id
            and    bill_id = p_bill_id
            and    ft_type_flg in ('AD', 'AX')
            and    trim(parent_id) like 'CM-GSL%' having
             sum(cur_amt) <> 0;
        exception
            when no_data_found then
                l_adj_gsl := 0;
        end;

        if nvl(l_adj_gsl, 0) <> 0
        then
            l_cmdm_amt := l_cmdm_amt - l_adj_gsl;
            add_detail_line(p_tran_no, 'ADJGSL', null, l_adj_gsl);
        end if;

        if l_cmdm_amt < 0
        then
            add_detail_line(p_tran_no, 'nCCBADJ', null, l_cmdm_amt);
        elsif l_cmdm_amt > 0
        then
            add_detail_line(p_tran_no, 'pCCBADJ', null, l_cmdm_amt);
        end if;
    end insert_adj;

    /*
    Version History

    v1.2.5 by KDIONES on Nov 08, 2018
             Purpose of Change :  1175 VECO - Additional ID Format for 14 Digit TIN # in CCB
             Remarks  : adjust substring function from 16 to 20

    */

    function get_tin(p_acct_id in varchar2) return varchar2 as
        /*
          Author  :
          Purpose : this function will return the TIN of the particular customer
        */
        --Version History
        /*--------------------------------------------------------
           v1.2.0 02-FEB-2017 AOCARCALLAS
           Remarks : modify sql from per_id.per_id_nbr to substr(per_id.per_id_nbr, 1, 16)

        */
        --------------------------------------------------------
        tin_l varchar2(20);
    begin
        begin
            select substr(per_id.per_id_nbr, 1, 20)
            into   tin_l
            from   ci_per_id per_id, ci_acct_per acct_per
            where  per_id.per_id = acct_per.per_id
            and    per_id.id_type_cd = 'TIN     '
            and    acct_per.main_cust_sw = 'Y'
            and    acct_id = p_acct_id;
        exception
            when no_data_found then
                null;
            when too_many_rows then
                null;
        end;

        return tin_l;
    end get_tin;

    procedure populate_bp_bir_2013(p_tran_no in number,
                                   p_bill_id in varchar2) as
        --Version History
        /*--------------------------------------------------------
        v1.4.2 by gperater on January 30, 2024
                remarks : new sum for line code RPT (Real Property Tax) separate computation as this line is vatable current set up
                         is it will sum up on vat exempt
         v1.4.1 by gperater on January 10, 2024
                remarks : new sum for line code FCT (Franchise Local Tax) separate computation as this line is vatable current set up
                         is it will sum up on vat exempt
         v1.3.9.6 by rreston on June 08, 2023

             Remarks : revised existing procedure in relation to CM 1678: VECO New Transmission Charge Allocation / UCME true up
                       removed <> condition for BIR 2306 PPVAT - Transco in procedure populate_bp_bir_2013

        v1.4.0 by LGYAP on March 30, 2017
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
        --------------------------------------------------------

        total_sales_l      number;
        vat1_l             number;
        net_of_vat_l       number;
        bir_2306_l         number;
        bir_2307_l         number;
        sc_pwd_disc_l      number;
        amount_due_l       number;
        vat2_l             number;
        total_amount_due_l number;
        vatable_sales_l    number;
        vat_exempt_sales_l number;
        vat_0rated_sales_l number;
        vat_amount_l       number;
        total_sales2_l     number;
        err_line_l         number;
        errmsg_l           varchar2(2000);
    begin
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

        begin
            -- for total sales
            -- Total Sales(VAT Inclusive)
            select nvl(bill_amt, 0)
            into   total_sales_l
            from   bp_headers
            where  tran_no = p_tran_no;
        end;

        err_line_l := 20;

        begin
            -- for total vat
            -- Less : VAT
            select nvl(sum(line_amount), 0)
            into   vat1_l
            from   bp_details
            where  line_code like 'VAT-%'
            and    tran_no = p_tran_no;
        end;

        err_line_l := 30;

        begin
            -- Amount Net of VAT
            net_of_vat_l := total_sales_l - vat1_l;
        end;

        err_line_l := 40;

        begin
            -- for total amount of BIR 2306
            -- Less : BIR 2306
            select nvl(abs(sum(calc_ln.calc_amt)), 0)
            into   bir_2306_l
            from   ci_bseg bseg, ci_bseg_calc_ln calc_ln
            where  bseg.bseg_id = calc_ln.bseg_id
            and    bseg.bseg_stat_flg in ('50', '70') -->> v1.5.1
            and    bseg.bill_id = p_bill_id
            and    calc_ln.descr_on_bill like 'BIR 2306 PPVAT%';
            -- and    calc_ln.descr_on_bill <> 'BIR 2306 PPVAT - Transco';
        end;

        err_line_l := 50;

        begin
            -- for total amount of BIR_2307
            -- BIR 2307
            select nvl(abs(sum(calc_ln.calc_amt)), 0)
            into   bir_2307_l
            from   ci_bseg bseg, ci_bseg_calc_ln calc_ln
            where  bseg.bseg_id = calc_ln.bseg_id
            and    bseg.bseg_stat_flg in ('50', '70') -->> v1.5.1
            and    bseg.bill_id = p_bill_id
            and    calc_ln.descr_on_bill like 'BIR 2307 PPWTAX%';
        end;

        err_line_l := 60;

        begin
            -- for total amount of senior citizen discount or pwd discount
            -- SC/PWS DISCOUNT
            select nvl(abs(sum(calc_ln.calc_amt)), 0)
            into   sc_pwd_disc_l
            from   ci_bseg bseg, ci_bseg_calc_ln calc_ln
            where  bseg.bseg_id = calc_ln.bseg_id
            and    bseg.bseg_stat_flg in ('50', '70') -->> v1.5.1
            and    bseg.bill_id = p_bill_id
            and    calc_ln.char_type_cd = 'CM-SCCAT';
        end;

        err_line_l := 70;

        begin
            -- for net amount
            -- Amount Due
            amount_due_l := net_of_vat_l -
                            (bir_2306_l + bir_2307_l + sc_pwd_disc_l);
        end;

        err_line_l := 80;

        begin
            -- for vat
            --Add : VAT

            vat2_l := vat1_l;
        end;

        err_line_l := 90;

        begin
            -- TOTAL AMOUNT DUE
            total_amount_due_l := amount_due_l + vat1_l;
        end;

        --2nd part
        err_line_l := 100;

        begin
            -- for vatables sales
            if (vat1_l = 0)
            then
                vatable_sales_l := 0;
            else
                vatable_sales_l := total_sales_l;
            end if;
        end;

        err_line_l := 110;

        begin
            -- for vat exempt sales
            vat_exempt_sales_l := 0;
        end;

        err_line_l := 120;

        begin
            -- for vat zero rated sales
            if (vat1_l = 0)
            then
                vat_0rated_sales_l := total_sales_l;
            else
                vat_0rated_sales_l := 0;
            end if;
        end;

        err_line_l := 130;

        begin
            -- for vat amount
            vat_amount_l := vat1_l;
        end;

        err_line_l := 140;

        begin
            -- for total sales
            total_sales2_l := total_sales_l - vat1_l;
        end;

        --v1.4.0 by LGYAP on March 30, 2017
        declare
            l_gen_total number;
            l_dst_total number;
            l_oth_total number;
            l_gov_total number;
            l_lft_total number; --01/09/2024
            l_rpt_total number; --01/30/2024

            l_x_vat_amt        number;
            l_x_vatable_amt    number;
            l_x_vat_exempt_amt number;
            l_x_zero_rated_amt number;
            l_x_total_amt      number;
        begin
            err_line_l := 150;
            select sum(decode(line_code, 'vGENTRANSTOT', line_amount, 0)) gen,
                   sum(decode(line_code, 'vDISTREVTOT', line_amount, 0)) dst,
                   sum(decode(line_code, 'vOTHTOT', line_amount, 0)) oth,
                   sum(decode(line_code, 'vGOVTOT', line_amount, 0)) gov,
                   sum(decode(line_code, 'FCT', line_amount, 0)) lft, --01/09/2024 RPTKWH
                   sum(decode(line_code, 'RPTKWH', line_amount,
                                         'RPTW', line_amount, 0)) rpt
            into   l_gen_total, l_dst_total, l_oth_total, l_gov_total, l_lft_total, l_rpt_total
            from   bp_details
            where  tran_no = p_tran_no
            and    line_code in
                   ('vGENTRANSTOT', 'vDISTREVTOT', 'vOTHTOT', 'vGOVTOT', 'FCT', 'RPTKWH', 'RPTW');

            err_line_l := 160;
            l_x_vat_amt := vat1_l;
            l_x_vatable_amt := l_gen_total + l_dst_total + l_oth_total + l_lft_total + l_rpt_total;
            l_x_zero_rated_amt := 0;
            l_x_vat_exempt_amt := l_gov_total - l_x_vat_amt - l_lft_total - l_rpt_total;
            l_x_total_amt := total_sales_l;

            if (l_x_vat_amt = 0)
            then
                l_x_zero_rated_amt := l_x_vatable_amt;
                l_x_vatable_amt := 0;
            end if;

            err_line_l := 170;
            vatable_sales_l := l_x_total_amt;
            vat_exempt_sales_l := l_x_vat_exempt_amt;
            vat_0rated_sales_l := l_x_zero_rated_amt;
            vat_amount_l := l_x_vat_amt;
            total_sales2_l := l_x_vatable_amt;
        end;

        begin
            err_line_l := 180;
            insert into bp_bir_2013
                (tran_no,
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
                 total_sales2)
            values
                (p_tran_no,
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
                 total_sales2_l);
        end;
    exception
        when others then
            log_error('Bill ID :' || p_bill_id || '-Tran No' || p_tran_no,
                      sqlerrm,
                      'Error while inserting BP BIR 2013 @ line ' ||
                      err_line_l,
                      null,
                      null,
                      null,
                      null);
    end populate_bp_bir_2013;

    function get_bill_messages(p_bill_no in varchar2) return varchar2 as
        l_bill_msg_code varchar2(90);

        l_bp_message_code varchar2(90);
        l_bp_message_text varchar2(3000);

        l_msg_code varchar2(90);
    begin
        l_msg_code := null;
        l_bp_message_code := null;
        l_bp_message_text := null;

        for l_msg_cur in (select distinct bill_msg_cd
                          from   ci_bill_msgs
                          where  bill_id = p_bill_no
                          order  by bill_msg_cd)
        loop
            l_bill_msg_code := trim(l_msg_cur.bill_msg_cd);

            if l_bill_msg_code in ('1400',
                                   '1401',
                                   '1402',
                                   '1403',
                                   '1404',
                                   '1405',
                                   '1406',
                                   '1407',
                                   '1408',
                                   '1409',
                                   '1410',
                                   '1411',
                                   'ABDR')
            then
                declare
                    l_code varchar2(90);
                    l_text varchar2(3000);
                begin
                    select trim(message_code), trim(message_text)
                    into   l_code, l_text
                    from   bp_message_codes
                    where  message_code = l_bill_msg_code;

                    if l_bp_message_code is null
                    then
                        l_bp_message_code := l_code;
                        l_bp_message_text := l_text;
                    else
                        l_bp_message_code := l_bp_message_code || l_code;
                        l_bp_message_text := l_bp_message_text || chr(10) ||
                                             l_text;
                    end if;
                exception
                    when no_data_found then
                        log_error(p_bill_no || ' ' ||
                                  l_msg_cur.bill_msg_cd,
                                  'Message code not found - ' || sqlerrm,
                                  null,
                                  null,
                                  null,
                                  null);
                        raise_application_error(-20040,
                                                'bill_no: ' || p_bill_no || ' ' ||
                                                sqlerrm);
                end;
            end if;
        end loop;

        if l_bp_message_code is not null
        then
            declare
                l_found number(1);
            begin
                select 1
                into   l_found
                from   bp_message_codes
                where  message_code = l_bp_message_code;
            exception
                when no_data_found then
                    begin
                        insert into bp_message_codes
                            (message_code, description, message_text)
                        values
                            (l_bp_message_code,
                             'Combination:' || l_bp_message_code,
                             l_bp_message_text);
                    exception
                        when dup_val_on_index then
                            null;
                    end;
            end;

            l_msg_code := l_bp_message_code;
        end if;

        return l_msg_code;
    exception
        when others then
            log_error('p_bill_no: ' || p_bill_no,
                      'Error @ function get_bill_messages - ' || sqlerrm,
                      null,
                      null,
                      null,
                      null);
            rollback;
    end get_bill_messages;

    procedure populate_bill_msg_param(p_tran_no      in number,
                                      p_bill_id      in varchar2,
                                      p_message_code in varchar2) as
        l_errmsg  varchar2(3000);
        l_errline number;
    begin
        l_errline := 10;

        if (p_message_code = 'LB01')
        then
            declare
                l_total_amt_due     number;
                l_prev_reading_date date;
                l_curr_reading_date date;
            begin
                select max(hdr.total_amt_due),
                       min(mtr.prev_reading_date),
                       max(mtr.curr_reading_date)
                into   l_total_amt_due,
                       l_prev_reading_date,
                       l_curr_reading_date
                from   bp_headers hdr, bp_meter_details mtr
                where  hdr.tran_no = mtr.tran_no
                and    hdr.tran_no = p_tran_no;

                delete from bp_message_param where tran_no = p_tran_no;

                insert into bp_message_param
                values
                    (p_tran_no,
                     p_message_code,
                     1,
                     to_char(l_prev_reading_date, 'fmMonth YYYY'));

                insert into bp_message_param
                values
                    (p_tran_no,
                     p_message_code,
                     2,
                     to_char(l_curr_reading_date, 'fmMonth YYYY'));

                insert into bp_message_param
                values
                    (p_tran_no,
                     p_message_code,
                     3,
                     to_char(l_total_amt_due, 'fm999,999,990.00'));
            end;
        else
            insert into bp_message_param
                select p_tran_no tran_no,
                       trim(bill_msg_cd) bill_msg_cd,
                       seq_num,
                       msg_parm_val
                from   ci_bill_msg_prm
                where  bill_id = p_bill_id;
        end if;
    exception
        when others then
            l_errmsg := 'Error @ function POPULATE_BILL_MSG_PARAM - ' ||
                        sqlerrm;
            log_error('p_bill_no: ' || p_bill_id,
                      l_errmsg,
                      null,
                      null,
                      null,
                      null);
            rollback;
            raise_application_error(-20201, l_errmsg);
    end populate_bill_msg_param;

    procedure adjust_tou_presentation(p_tran_no in number,
                                      p_bill_id in varchar2,
                                      p_sa_id   in varchar2) as
        l_billed_kwhr_cons   number;
        l_billed_demand_cons number;
        l_billed_kvar_cons   number;

        l_badge_no          varchar2(45);
        l_serial_no         varchar2(45);
        l_conn_load         number;
        l_pole_no           varchar2(30);
        l_multiplier        number;
        l_prev_reading_date date;
        l_curr_reading_date date;

        l_gentou number;

        l_bill_amt number;
        l_vat_amt  number;
        l_uc_amt   number;
        l_i_cera   number;
        l_2307     number;
        l_2306     number;

        l_errmsg varchar2(3000);
        l_line   number;
        l_errfound exception;
    begin
        begin
            l_line := 10;

            select nvl(max(bill_sq), 0)
            into   l_billed_kwhr_cons
            from   ci_bseg bseg, ci_bseg_sq sq
            where  bseg.bseg_id = sq.bseg_id
            and    bseg.bseg_stat_flg in ('50', '70') -->> v1.5.1
            and    bseg.bill_id = p_bill_id
            and    bseg.sa_id = p_sa_id
            and    sq.sqi_cd = 'CMBKWHT ';

            l_line := 20;

            select nvl(max(bill_sq), 0)
            into   l_billed_demand_cons
            from   ci_bseg bseg, ci_bseg_sq sq
            where  bseg.bseg_id = sq.bseg_id
            and    bseg.bseg_stat_flg in ('50', '70') -->> v1.5.1
            and    bseg.bill_id = p_bill_id
            and    bseg.sa_id = p_sa_id
            and    sq.sqi_cd = 'CMBKWT  ';

            l_line := 30;

            select nvl(max(bill_sq), 0)
            into   l_billed_kvar_cons
            from   ci_bseg bseg, ci_bseg_sq sq
            where  bseg.bseg_id = sq.bseg_id
            and    bseg.bseg_stat_flg in ('50', '70') -->> v1.5.1
            and    bseg.bill_id = p_bill_id
            and    bseg.sa_id = p_sa_id
            and    sq.sqi_cd = 'CMBKVART';

            if (l_billed_kwhr_cons = 0)
            then
                l_errmsg := 'l_billed_kwhr is 0';
                raise l_errfound;
            end if;

            l_line := 40;

            update bp_headers
            set    billed_kwhr_cons   = l_billed_kwhr_cons,
                   billed_demand_cons = l_billed_demand_cons,
                   billed_kvar_cons   = l_billed_kvar_cons
            where  tran_no = p_tran_no;
        end;

        begin
            l_line := 50;

            begin
                select mtr.badge_nbr,
                       mtr.serial_nbr,
                       (select bill_sq
                        from   ci_bseg_sq
                        where  bseg_id = bseg.bseg_id
                        and    sqi_cd = 'CONNLOAD') conn_load,
                       (select max(geo_val)
                        from   ci_sp_geo spg
                        where  spg.sp_id = sa_sp.sp_id
                        and    spg.geo_type_cd like 'POLENO%') pole_no,
                       reg.reg_const multiplier,
                       bseg.start_dt prev_reading_date,
                       bseg.end_dt curr_reading_date
                into   l_badge_no,
                       l_serial_no,
                       l_conn_load,
                       l_pole_no,
                       l_multiplier,
                       l_prev_reading_date,
                       l_curr_reading_date
                from   ci_bseg bseg,
                       ci_sa_sp sa_sp,
                       ci_sp_mtr_hist mtr_hist,
                       ci_mtr_config mtr_config,
                       ci_mtr mtr,
                       ci_reg reg
                where  bseg.sa_id = sa_sp.sa_id
                and    sa_sp.sp_id = mtr_hist.sp_id
                and    mtr_hist.mtr_config_id = mtr_config.mtr_config_id
                and    mtr_config.mtr_id = mtr.mtr_id
                and    mtr.mtr_id = reg.mtr_id
                and    bseg.bseg_stat_flg in ('50', '70') -->> v1.5.1
                and    bseg.bill_id = p_bill_id
                and    bseg.sa_id = p_sa_id
                and    sa_sp.usage_flg = '+ '
                and    mtr_hist.removal_dttm is null
                and    reg.intv_reg_type_cd = 'CM_KWH60  ';
            exception
                when too_many_rows then
                    log_error('p_bill_no: ' || p_bill_id,
                              sqlerrm,
                              'Error in function adjust_tou_presentation @ ' ||
                              to_char(l_line) || '- multiple rows return',
                              null,
                              null,
                              null);
            end;

            l_line := 60;

            update bp_meter_details
            set    badge_no          = l_badge_no,
                   serial_no         = l_serial_no,
                   pole_no           = l_pole_no,
                   multiplier        = l_multiplier,
                   prev_reading_date = l_prev_reading_date,
                   curr_reading_date = l_curr_reading_date,
                   conn_load         = l_conn_load,
                   prev_kwhr_rdg     = 0,
                   curr_kwhr_rdg     = l_billed_kwhr_cons,
                   reg_kwhr_cons     = l_billed_kwhr_cons,
                   prev_demand_rdg   = 0,
                   curr_demand_rdg   = l_billed_demand_cons,
                   reg_demand_cons   = l_billed_demand_cons,
                   prev_kvar_rdg     = 0,
                   curr_kvar_rdg     = l_billed_kvar_cons,
                   reg_kvar_cons     = l_billed_kvar_cons
            where  tran_no = p_tran_no;
        exception
            when no_data_found then
                l_errmsg := 'error while populating tou bp_meter_details';
                raise l_errfound;
        end;

        begin
            l_line := 70;

            select nvl(sum(line_amount), 0)
            into   l_gentou
            from   bp_details
            where  tran_no = p_tran_no
            and    line_code in
                   ('GEN-TOU', 'SFX-TOU', 'MFC-TOU', 'INC-TOU');

            l_line := 80;

            update bp_details
            set    line_amount = l_gentou
            where  tran_no = p_tran_no
            and    line_code = 'GEN-TOU';

            l_line := 90;

            delete from bp_details
            where  tran_no = p_tran_no
            and    line_code in ('SFX-TOU', 'MFC-TOU', 'INC-TOU');
        exception
            when no_data_found then
                l_errmsg := 'no data for tou bp_details';
                raise l_errfound;
        end;

        begin
            l_line := 100;

            select nvl(total_sales, 0) total_sales, nvl(vat1, 0) vat1
            into   l_bill_amt, l_vat_amt
            from   bp_bir_2013
            where  tran_no = p_tran_no;

            l_line := 110;

            select nvl(sum(calc_amt), 0)
            into   l_uc_amt
            from   ci_bseg_calc_ln calc, ci_bseg bseg
            where  calc.bseg_id = bseg.bseg_id
            and    bseg.bseg_stat_flg in ('50', '70') -->> v1.5.1
            and    bseg.bill_id = p_bill_id
            and    bseg.sa_id = p_sa_id
            and    calc.descr_on_bill like 'Universal Charge%';

            l_line := 120;

            select nvl(sum(calc_amt), 0)
            into   l_i_cera
            from   ci_bseg_calc_ln calc, ci_bseg bseg
            where  calc.bseg_id = bseg.bseg_id
            and    bseg.bseg_stat_flg in ('50', '70') -->> v1.5.1
            and    bseg.bill_id = p_bill_id
            and    bseg.sa_id = p_sa_id
            and    calc.descr_on_bill like '%CERA Charge%';

            l_line := 130;
            l_2306 := (l_vat_amt * 5) / 12;
            l_2307 := (l_bill_amt - (l_vat_amt + l_uc_amt + l_i_cera)) * 0.02;

            l_line := 140;

            update bp_bir_2013
            set    bir_2307 = l_2307, bir_2306 = l_2306
            where  tran_no = p_tran_no;

            l_line := 150;

            update bp_bir_2013
            set    amount_due = amount_due - (bir_2307 + bir_2306)
            where  tran_no = p_tran_no;

            l_line := 160;

            update bp_bir_2013
            set    total_amount_due = amount_due + vat2
            where  tran_no = p_tran_no;
        exception
            when no_data_found then
                l_errmsg := 'error while populating tou bp_bir_2013';
                raise l_errfound;
        end;

        begin
            l_line := 170;

            insert into bp_consumption_hist
                (tran_no, rdg_date, consumption)
                select p_tran_no, trunc(rdg_date), sum(consumption)
                from   (select distinct bs.end_dt rdg_date,
                                        bsq.bill_sq consumption
                        from   ci_bseg bs, ci_bseg_sq bsq
                        where  bs.bseg_id = bsq.bseg_id
                        and    bsq.sqi_cd = rpad('CMBKWT', 8)
                        and    bs.bseg_stat_flg in ('50', '70')
                        and    bs.sa_id = p_sa_id
                        and    bs.end_dt <= l_curr_reading_date
                        order  by bs.end_dt desc)
                where  rownum <= 13
                group  by trunc(rdg_date);
        end;
    exception
        when l_errfound then
            log_error('p_bill_no: ' || p_bill_id,
                      l_errmsg,
                      'Error in function adjust_tou_presentation @ ' ||
                      to_char(l_line),
                      null,
                      null,
                      null);
            --raise_application_error(-20010,sqlerrm);
        when others then
            log_error('p_bill_no: ' || p_bill_id,
                      sqlerrm,
                      'Error in function adjust_tou_presentation @ ' ||
                      to_char(l_line),
                      null,
                      null,
                      null);
            --raise_application_error(-20010,sqlerrm);
    end adjust_tou_presentation;

    procedure update_alt_id_2_zero(p_date_from in date, p_date_to in date) as
    begin
        begin
            update ci_bill
            set    alt_bill_id = 0
            where  bill_stat_flg = 'C'
            and    complete_dttm >= trunc(p_date_from)
            and    complete_dttm < trunc(p_date_to) + 1
            and    alt_bill_id = 1;
        exception
            when others then
                log_error('date : ' || to_char(p_date_from, 'MM/DD/YYYY') || '-' ||
                          to_char(p_date_to, 'MM/DD/YYYY'),
                          sqlerrm,
                          'Error in procedure update_alt_id_2_zero ',
                          null,
                          null,
                          null);
        end;
    end update_alt_id_2_zero;

    procedure update_adjocs_alt_bill_id(p_date_from in date,
                                        p_date_to   in date) as
        l_line number;
    begin
        l_line := 10;

        for l_cur in (select bill_no, tran_no
                      from   bp_headers
                      where  du_set_id = 1
                      and    complete_date >= trunc(p_date_from)
                      and    complete_date < trunc(p_date_to) + 1
                      and    alt_bill_id in ('1', '0'))
        loop
            l_line := 20;

            declare
                l_alt_bill_id varchar2(20);
            begin
                l_line := 30;

                select to_char(alt_bill_id)
                into   l_alt_bill_id
                from   ci_bill
                where  bill_id = l_cur.bill_no;

                l_line := 40;

                update bp_headers
                set    alt_bill_id = l_alt_bill_id
                where  tran_no = l_cur.tran_no;
            end;
        end loop;

        commit;
    exception
        when others then
            log_error('date : ' || to_char(p_date_from, 'MM/DD/YYYY') || '-' ||
                      to_char(p_date_to, 'MM/DD/YYYY'),
                      sqlerrm,
                      'Error in procedure update_adjocs_alt_bill_id @ ' ||
                      to_char(l_line),
                      null,
                      null,
                      null);
            --raise_application_error(-20002, sqlerrm);
    end update_adjocs_alt_bill_id;

    procedure update_power_cust_du_set_id(p_date_from in date,
                                          p_date_to   in date) as
        l_line      number;
        l_du_set_id number;
    begin
        l_line := 10;

        select bph_du_set_id_pf.nextval into l_du_set_id from dual;

        l_line := 20;

        update bp_headers
        set    du_set_id = l_du_set_id
        where  complete_date >= p_date_from
        and    complete_date < p_date_to + 1
        and    rate_schedule in ('01-F-11',
                                 '01-F-12',
                                 '04-P-46',
                                 '04-P-46T',
                                 '04-P-47',
                                 '04-P-48',
                                 '04-P-49',
                                 '05-P-50',
                                 '05-P-55',
                                 '06-P-60',
                                 '06-P-65',
                                 '07-P-70',
                                 '07-P-75',
                                 '07-W-72',
                                 '06-IR-60',
                                 '07-IR-70');

        commit;
    exception
        when others then
            log_error('date : ' || to_char(p_date_from, 'MM/DD/YYYY') || '-' ||
                      to_char(p_date_to, 'MM/DD/YYYY'),
                      sqlerrm,
                      'Error in procedure update_power_cust_du_set_id @ ' ||
                      to_char(l_line),
                      null,
                      null,
                      null);
            rollback;
            --raise_application_error(-20002, sqlerrm);
    end update_power_cust_du_set_id;

    procedure extract_bills(p_batch_cd  in varchar2,
                            p_batch_nbr in number,
                            p_du_set_id in number,
                            p_thread_no in number default 1,
                            p_first_row in number default null,
                            p_last_row  in number default null,
                            p_bill_id   in varchar2 default null) is
        --Version History
        /*--------------------------------------------------------
           v1.4.1 07-APR-2017 AOCARCALLAS
           Remarks : Revise BCConejos code to query the old table when new table has no data.
                     -- tag for_ebill_account
           v1.3.0 08-mar-2017 BCConejos
           Remarks : [aocarcallas] BCConejos forgot to add history.
                     -- tag for_ebill_account [switch table from ebill_accounts to ebill_statement_accounts]
           v1.2.0 02-FEB-2017 AOCARCALLAS
           Remarks : populate tin, business style  address
                     -- get business style
                     -- retrieve business address

        */
        --------------------------------------------------------

        cursor bill_routes_cur is
            select *
            from   (select dense_rank() over(order by br.rowid) row_number,
                           br.batch_cd,
                           br.batch_nbr,
                           br.bill_id,
                           br.entity_name1 customer_name,
                           br.address1,
                           br.address2,
                           br.address3,
                           br.city,
                           trim(b.bill_cyc_cd) billing_batch_no,
                           trunc(b.win_start_dt, 'MONTH') bill_month,
                           b.bill_dt,
                           b.due_dt,
                           trim(bchar.char_val) bill_color, -- decode(substr(br.batch_cd, -1), 'G', 'GREEN', 'RED') bill_color,
                           b.acct_id acct_no,
                           b.complete_dttm,
                           br.no_batch_prt_sw,
                           b.alt_bill_id
                    from   ci_bill_routing br, ci_bill b, ci_bill_char bchar
                    where  br.bill_id = b.bill_id
                    and    b.bill_id = bchar.bill_id
                    and    b.bill_stat_flg = 'C'
                    and    br.bill_rte_type_cd in ('POSTAL', 'POSTAL2')
                    and    bchar.char_type_cd = 'BILLIND '
                    and    bchar.seq_num = 1 --only the first entry in the bill characteristics
                    and    br.seqno = 1 -- just get the first entry in the bill routing
                    and    br.batch_cd = rpad(p_batch_cd, 8)
                    and    br.batch_nbr = p_batch_nbr
                    and    b.bill_id = nvl(p_bill_id, b.bill_id) --and    not exists (select null from bp_headers where bill_no = b.bill_id)
                    and    not exists
                     (select null
                            from   bp_headers
                            where  bill_no = br.bill_id) -->> v1.5.1
                    )
            where  row_number >= nvl(p_first_row, 1)
            and    row_number <= nvl(p_last_row, 1000000000);

        type br_tab_type is table of bill_routes_cur%rowtype index by binary_integer;

        l_br  br_tab_type;
        l_row pls_integer;

        l_du_set_id  number;
        l_total_recs number;
        l_curr_rec   number := 0;

        l_bph bp_headers%rowtype;

        l_main_sa_id   ci_sa.sa_id%type;
        l_main_sa_dt   date;
        l_main_prem_id ci_sa.char_prem_id%type;

        l_bill_amt       bp_headers.bill_amt%type;
        l_estimate_note  varchar2(20);
        l_other_bseg_amt number;
        l_cmdm_amt       number;

        l_start_dttm    date;
        l_end_dttm      date;
        l_ebill_only_sw char(1);
        l_alt_bill_id   varchar2(20);
        l_txt_only      varchar2(1);
        l_bd_amt        number; --03/06/2024
    begin
        -- update the batch control
        -- increment the batch number so that the next extract will be
        -- grouped under a new batch number
        if p_bill_id is null
        then
            begin
                update ci_batch_ctrl
                set    next_batch_nbr = next_batch_nbr + 1
                where  batch_cd = rpad(p_batch_cd, 8)
                and    next_batch_nbr = p_batch_nbr;

                -- commit right away, so other threads will not be waiting for the
                -- lock on the record to be released
                commit;
            exception
                when others then
                    log_error('Updating Batch Control',
                              sqlerrm,
                              null,
                              'CI_BATCH_CTRL',
                              p_batch_cd,
                              p_batch_nbr,
                              p_thread_no);
                    raise_application_error(-20002, sqlerrm);
            end;
        end if;

        l_start_dttm := sysdate;
        dbms_application_info.set_module('BPX:' ||
                                         to_char(l_start_dttm,
                                                 'hh24:mi:ss'),
                                         'Extracting Bills');

        dbms_application_info.set_client_info('TRD-' ||
                                              to_char(p_thread_no, 'fm00') ||
                                              ': Initializing please wait...');

        -- count total rows to process
        if p_bill_id is not null
        then
            l_total_recs := 1;
        elsif p_first_row is not null and p_last_row is not null
        then
            l_total_recs := (p_last_row - p_first_row) + 1;
        else
            l_total_recs := get_extract_bill_count(p_batch_cd, p_batch_nbr);
        end if;

        dbms_application_info.set_client_info('TRD-' ||
                                              to_char(p_thread_no, 'fm00') ||
                                              ': Total Records - ' ||
                                              to_char(l_total_recs,
                                                      'fm999,999,999'));

        open bill_routes_cur;

        loop
            fetch bill_routes_cur bulk collect
                into l_br limit 1000;

            l_row := l_br.first;

            while (l_row is not null)
            loop
                -- intialize bp_header record
                l_bph := null;

                l_curr_rec := l_curr_rec + 1;

                dbms_application_info.set_client_info('TRD-' ||
                                                      to_char(p_thread_no,
                                                              'fm00') || ': ' ||
                                                      to_char(l_curr_rec) || '/' ||
                                                      to_char(l_total_recs) || ' ' ||
                                                      to_char(ceil((l_curr_rec /
                                                                   l_total_recs) * 100)) || '% ');

                l_main_sa_id := null;
                l_main_sa_dt := to_date('01011900', 'mmddyyyy');
                l_main_prem_id := null;

                l_estimate_note := null;
                l_bph.overdue_amt := null;
                l_bph.overdue_bill_count := null;
                l_bph.bill_amt := null;

                for r2 in (select sa.sa_id,
                                  trim(st.dst_id) dst_id,
                                  trim(st.bill_seg_type_cd) bill_seg_type_cd,
                                  bs.end_dt,
                                  bs.est_sw,
                                  sa.char_prem_id
                           from   ci_bseg bs, ci_sa sa, ci_sa_type st
                           where  bs.sa_id = sa.sa_id
                           and    st.sa_type_cd = sa.sa_type_cd
                           and    bs.bseg_stat_flg in ('50', '70') -- Frozen/OK
                           and    bs.bill_id = l_br(l_row).bill_id
                           and    trim(st.dst_id) = 'A/R-ELEC'
                           and    sa.sa_type_cd not like 'NET-E%'
                           and    sa.sa_type_cd not like 'RCOA_DU%'
                           and    trim(st.bill_seg_type_cd) in
                                  ('SP-RATED', 'NOSP-RAT', 'BD-RATED'))
                loop
                    if r2.end_dt > l_main_sa_dt
                    then
                        l_main_sa_dt := r2.end_dt;
                        l_main_sa_id := r2.sa_id;
                        l_main_prem_id := r2.char_prem_id;

                        /*if l_br(l_row).bill_month is null
                        then
                           l_br(l_row).bill_month := trunc(r2.end_dt, 'MONTH');
                        end if;*/
                        l_br(l_row).bill_month := trunc(r2.end_dt, 'MONTH');

                        -- determine if bill is estimated
                        if r2.est_sw = 'Y'
                        then
                            l_bph.bill_type := 'E'; -- estimated
                            l_estimate_note := '(ESTIMATE)';
                        else
                            l_bph.bill_type := 'R'; -- regular
                        end if;

                        dbms_output.put_line('get_current_bill_amt');
                        l_bill_amt := get_current_bill_amt(l_br(l_row).bill_id,
                                                           r2.sa_id);

                        -- get current bill amount
                        l_bph.bill_amt := nvl(l_bph.bill_amt, 0) +
                                          l_bill_amt;

                        l_bph.overdue_amt := 0;

                        --if l_br(l_row).bill_color = 'RED'
                        --then
                        -- get over due amount
                        dbms_output.put_line('get_overdue_amt2');
                        l_bph.overdue_amt := nvl(l_bph.overdue_amt, 0) +
                                             get_overdue_amt90(l_br(l_row).bill_id);

                        if l_bph.overdue_amt <= 0
                        then
                            l_br(l_row).bill_color := 'GREEN';
                        else
                            dbms_output.put_line('get_overdue_bill_cnt');
                            --l_bph.overdue_bill_count := 1;
                            l_bph.overdue_bill_count := get_overdue_bill_cnt(r2.sa_id,
                                                                             l_br(l_row).bill_dt,
                                                                             l_bph.overdue_amt);
                        end if;

                        --end if;
                        dbms_output.put_line('get_par_kwh');
                        l_bph.par_kwhr := get_par_kwh(l_br(l_row).bill_id);
                        dbms_output.put_line('get_par_month');
                        l_bph.par_month := get_par_month(r2.sa_id,
                                                         r2.end_dt);
                    end if;
                end loop;

                -- if there is  a billed Electric SA, dont proceed
                if l_bph.bill_amt is not null
                then
                    -- *** This section gets the bill's pertinent info ***
                    -- *** or the not so critical data
                    dbms_output.put_line('get_crc');
                    -- get crc
                    l_bph.crc := get_crc(l_br(l_row).acct_no);
                    dbms_output.put_line('get_business_style');
                    -- get business style
                    l_bph.bus_activity := get_business_style(l_main_sa_id);
                    dbms_output.put_line('retrieve_business_address');
                    -- retrieve business address
                    retrieve_business_address(l_br(l_row).acct_no,
                                              l_bph.bus_add1,
                                              l_bph.bus_add2,
                                              l_bph.bus_add3,
                                              l_bph.bus_add4,
                                              l_bph.bus_add5);
                    dbms_output.put_line('retrieve_premise_address');
                    -- retrieve the premise address
                    retrieve_premise_address(l_main_prem_id,
                                             l_bph.premise_add1,
                                             l_bph.premise_add2,
                                             l_bph.premise_add3);
                    dbms_output.put_line('retrieve_rate_schedule');
                    -- get the rate schedule of the account being billed
                    retrieve_rate_schedule(l_br(l_row).bill_id,
                                           l_main_sa_id,
                                           l_bph.rate_schedule,
                                           l_bph.rate_schedule_desc);
                    dbms_output.put_line('get_default_courier');
                    -- get default courier code based on the rate schedule
                    l_bph.courier_code := get_default_courier(l_bph.rate_schedule,
                                                              l_br               (l_row).billing_batch_no,
                                                              l_br               (l_row).acct_no);
                    dbms_output.put_line('get_area_code');
                    -- get area code, derived from bill routing city
                    l_bph.area_code := get_area_code(l_br(l_row).city);
                    dbms_output.put_line('retrieve_last_payment');
                    -- get the last payment event, date and amount
                    retrieve_last_payment(l_br                     (l_row).acct_no,
                                          l_br                     (l_row).bill_dt,
                                          l_bph.last_payment_date,
                                          l_bph.last_payment_amount);
                    dbms_output.put_line('get_book_no');
                    -- get book no. or service route
                    l_bph.book_no := get_book_no(l_main_sa_id);
                    dbms_output.put_line('get_bdseq');
                    -- get delivery sequence
                    l_bph.new_seq_no := get_bdseq(l_br(l_row).acct_no);
                    dbms_output.put_line('get_bdmsgr');
                    -- get messenger code
                    l_bph.messenger_code := get_bdmsgr(l_br(l_row).acct_no);

                    -- get bill message
                    l_bph.message_code := get_bill_message(l_br(l_row).bill_id);

                    -- *** This section retrieves the critical info of the bill

                    -- get billed consumptions from bseg_sq
                    l_bph.billed_kwhr_cons := get_bill_sq(l_br(l_row).bill_id,
                                                          l_main_sa_id,
                                                          'BILLKWH');
                    l_bph.billed_kvar_cons := get_bill_sq(l_br(l_row).bill_id,
                                                          l_main_sa_id,
                                                          'BILLKVAR');
                    l_bph.billed_demand_cons := get_bill_sq(l_br(l_row).bill_id,
                                                            l_main_sa_id,
                                                            'BILLKW');
                    l_bph.power_factor_value := get_bill_sq(l_br(l_row).bill_id,
                                                            l_main_sa_id,
                                                            'BILLPF');

                    -- get net bill amount
                    l_bph.total_amt_due := get_net_bill_amt2(l_br(l_row).bill_id);

                    -- get billing cycle
                    l_bph.billing_batch_no := l_br(l_row).billing_batch_no;

                    if trim(l_bph.billing_batch_no) is null
                    then
                        l_bph.billing_batch_no := get_billing_cycle(l_br(l_row).acct_no);
                    end if;

                    -- tag for_ebill_account
                    begin
                        select decode(print_sw, 'N', 'Y', 'N')
                        into   l_ebill_only_sw
                        from   ebill_statement_accounts
                        where  acct_id = l_br(l_row).acct_no
                        and    status = 'ACTIVE';
                    exception
                        when others then
                            begin
                                select 'Y'
                                into   l_ebill_only_sw
                                from   ebill_accounts
                                where  acct_id = l_br(l_row).acct_no
                                and    incld_in_batch_pr_sw = 'N'
                                and    enabled = 1;
                            exception
                                when no_data_found then
                                    l_ebill_only_sw := 'N';
                                when too_many_rows then
                                    l_ebill_only_sw := 'Y';
                                when others then
                                    l_ebill_only_sw := 'N';
                            end;
                    end;

                    -- get tag for ebill_txt_account
                    l_txt_only := get_text_only_tag(l_br(l_row).acct_no); -->> v1.3.9.5

                    -- get tin
                    l_bph.tin := get_tin(l_br(l_row).acct_no);

                    declare
                        l_temp_message_code varchar2(90);
                    begin
                        l_temp_message_code := get_bill_messages(l_br(l_row).bill_id);

                        if l_temp_message_code is not null
                        then
                            l_bph.message_code := l_temp_message_code;
                        end if;
                    end;

                    --getting CAS Sequence
                    l_alt_bill_id := l_br(l_row).alt_bill_id;

                    -- now create the header record for the bill
                    dbms_output.put_line('insert bp headers');
                    begin
                        insert into bp_headers
                            (du_set_id,
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
                             messenger_code,
                             par_month,
                             par_kwhr,
                             no_batch_prt_sw,
                             ebill_only_sw,
                             tin,
                             complete_date,
                             alt_bill_id,
                             bus_activity,
                             bus_add1,
                             bus_add2,
                             bus_add3,
                             bus_add4,
                             bus_add5,
                             txt_only)
                        values
                            (p_du_set_id,
                             l_br(l_row).batch_cd,
                             l_br(l_row).batch_nbr,
                             l_br(l_row).bill_id,
                             l_br(l_row).customer_name,
                             l_bph.premise_add1,
                             l_bph.premise_add2,
                             l_bph.premise_add3,
                             l_br(l_row).address1,
                             l_br(l_row).address2,
                             l_br(l_row).address3,
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
                             l_bph.messenger_code,
                             l_bph.par_month,
                             l_bph.par_kwhr,
                             l_br(l_row).no_batch_prt_sw,
                             l_ebill_only_sw,
                             l_bph.tin,
                             l_br(l_row).complete_dttm,
                             l_alt_bill_id,
                             l_bph.bus_activity,
                             l_bph.bus_add1,
                             l_bph.bus_add2,
                             l_bph.bus_add3,
                             l_bph.bus_add4,
                             l_bph.bus_add5,
                             l_txt_only)
                        returning tran_no into l_bph.tran_no;
                    exception
                        when dup_val_on_index then
                            log_error('Insert to headers',
                                      sqlerrm,
                                      'Duplicate Bill ID',
                                      'BP_HEADERS',
                                      p_batch_cd,
                                      p_batch_nbr,
                                      l_br(l_row).bill_id);
                            --raise_application_error(-20202, sqlerrm);

                        when others then
                            log_error('Insert to headers',
                                      sqlerrm,
                                      null,
                                      'BP_HEADERS',
                                      p_batch_cd,
                                      p_batch_nbr,
                                      l_br(l_row).bill_id);

                            dbms_application_info.set_action('Error Encountered.');

                            raise_application_error(-20201, sqlerrm);
                    end;

                    dbms_output.put_line('1');
                    if l_bph.tran_no is not null
                    then
                        -- insert bill message parameters
                        populate_bill_msg_param(l_bph.tran_no,
                                                l_br(l_row).bill_id,
                                                l_bph.message_code);

                        /*-- insert meter details
                        insert_meter_details(l_bph.tran_no,
                                             l_br         (l_row).bill_id,
                                             l_main_sa_id,
                                             l_br         (l_row).bill_dt);

                        -- insert consumption history
                        insert_consumption_hist(l_bph.tran_no,
                                                l_main_sa_id,
                                                l_br(l_row).bill_dt);
                        */

                        dbms_output.put_line('2');
                        -- insert meter details
                        cm_bp_extract_util_pkg.insert_meter_details(l_bph.tran_no,
                                                                    l_br         (l_row).bill_id,
                                                                    l_main_sa_id,
                                                                    l_br         (l_row).bill_dt);
                        dbms_output.put_line('3');
                        -- insert consumption history
                        insert_consumption_hist(l_bph.tran_no,
                                                l_main_sa_id,
                                                l_br(l_row).bill_dt);

                        dbms_output.put_line('4');
                        -- insert the bill's detail lines
                        insert_bp_details(l_bph.tran_no,
                                          l_br(l_row).bill_id,
                                          l_main_sa_id);

                        dbms_output.put_line('5');
                        -- insert bir 2013 requirements
                        populate_bp_bir_2013(l_bph.tran_no,
                                             l_br(l_row).bill_id);
                                             
                        

                        dbms_output.put_line('6');
                        -- insert additional info for the bill's detail lines
                        add_detail_line(l_bph.tran_no,
                                        'OVERDUE',
                                        null,
                                        l_bph.overdue_amt);

                        dbms_output.put_line('7');
                        add_detail_line(l_bph.tran_no,
                                        'CURBIL',
                                        to_char(l_br(l_row).bill_month,
                                                'fmMONTH YYYY') ||
                                        l_estimate_note,
                                        l_bph.bill_amt);

                        dbms_output.put_line('8');
                        add_detail_line(l_bph.tran_no,
                                        'OUTAMT',
                                        null,
                                        l_bph.total_amt_due);
                                        

                        dbms_output.put_line('9');
                        if l_br(l_row).bill_color = 'GREEN'
                        then
                            declare
                                l_apay_code   bp_detail_codes.code%type;
                                l_apay_src_cd ci_acct_apay.apay_src_cd%type;
                            begin
                                /*select code
                                into   l_apay_code
                                from   (select apay_src_cd, code
                                        from   ci_acct_apay apay,
                                               bp_detail_codes bp
                                        where  apay.apay_src_cd =
                                               bp.ccnb_descr_on_bill
                                        and    apay.acct_id = l_br(l_row).acct_no
                                        and    apay.end_dt is null)
                                where  rownum = 1;
                                */
                                select apay_src_cd
                                into   l_apay_src_cd
                                from   ci_acct_apay
                                where  acct_id = l_br(l_row).acct_no
                                and    end_dt is null;

                                select code
                                into   l_apay_code
                                from   bp_detail_codes
                                where  ccnb_descr_on_bill = l_apay_src_cd;

                                add_detail_line(l_bph.tran_no,
                                                l_apay_code,
                                                null,
                                                null);

                                add_detail_line(l_bph.tran_no,
                                                'CCBNOTICE',
                                                to_char(l_br(l_row).due_dt,
                                                        'MM/DD/YYYY'),
                                                null);
                            exception
                                when no_data_found then
                                    add_detail_line(l_bph.tran_no,
                                                    'CCBNOTICE',
                                                    to_char(l_br(l_row).due_dt,
                                                            'MM/DD/YYYY'),
                                                    null);
                            end;
                        else
                            add_detail_line(l_bph.tran_no,
                                            'CCBREDNOTICE',
                                            null,
                                            null);
                        end if;

                        dbms_output.put_line('10');
                        -- add info on last payment date and amount
                        if l_bph.last_payment_date is not null
                        then
                            add_detail_line(l_bph.tran_no,
                                            'CCBNOTICE1',
                                            'LAST PAYMENT  -  ' ||
                                            to_char(l_bph.last_payment_date,
                                                    'fmMONTH DD, YYYY') ||
                                            '  -  ' ||
                                            to_char(l_bph.last_payment_amount,
                                                    'fm9,999,999,990.00'),
                                            null);
                        end if;

                        l_other_bseg_amt := 0;

                        -- insert Payment Arrangements and such
                        if l_bph.total_amt_due <>
                           l_bph.bill_amt + l_bph.overdue_amt
                        then
                            insert_other_bseg(l_bph.tran_no,
                                              l_br(l_row).bill_id);
                            l_other_bseg_amt := get_other_bseg_amt(l_br(l_row).bill_id);

                        end if;
                        
                        -- insert BD bseg amt
                        if l_bph.total_amt_due <>
                           l_bph.bill_amt + l_bph.overdue_amt
                        then
                           insert_bd_bseg(l_bph.tran_no,
                                          l_br(l_row).bill_id);
                           l_other_bseg_amt := get_bd_bseg_amt(l_br(l_row).bill_id);
                        end if;

                        -- insert cmdm amount
                        l_cmdm_amt := l_bph.total_amt_due -
                                      (l_bph.bill_amt + l_other_bseg_amt +
                                      l_bph.overdue_amt);

                        if nvl(l_cmdm_amt, 0) <> 0
                        then
                            insert_adj(l_bph.tran_no,
                                       l_br(l_row).bill_id,
                                       l_main_sa_id,
                                       l_cmdm_amt);
                        end if;

                        if (bp_registry_pkg.get_value_asof('ECQ_ON') = 'Y')
                        then
                            add_ecq_info(l_bph.tran_no,
                                         l_br(l_row).bill_id,
                                         l_bph.total_amt_due);
                        end if;



                        /*if l_cmdm_amt < 0
                        then
                           add_detail_line (
                              l_bph.tran_no,
                              'nCCBADJ',
                              null,
                              l_cmdm_amt
                              );
                        elsif l_cmdm_amt > 0
                        then
                           add_detail_line (
                              l_bph.tran_no,
                              'pCCBADJ',
                              null,
                              l_cmdm_amt
                              );
                        end if;*/

                        if ((l_bph.rate_schedule_desc like '%TOU') or
                           (l_bph.rate_schedule like '%-IR-%'))
                        then
                            adjust_tou_presentation(l_bph.tran_no,
                                                    l_br(l_row).bill_id,
                                                    l_main_sa_id);
                        end if;
                        --remove_zero_line_amt
                        remove_zero_line_amt(l_bph.tran_no); --gperater 09/13/2023 v1.4.0
                    end if;
                end if;

                l_row := l_br.next(l_row);
            end loop;

            exit when bill_routes_cur%notfound;
        end loop; -- driving loop;

        close bill_routes_cur;

        commit;

        if p_bill_id is null
        then
            update_adjocs_alt_bill_id(trunc(sysdate), trunc(sysdate));
        end if;

        l_end_dttm := sysdate;
        dbms_application_info.set_action(to_char(l_end_dttm, 'hh24:mi:ss'));
        dbms_application_info.set_client_info('TRD-' ||
                                              to_char(p_thread_no, 'fm00') ||
                                              ': Done in ' ||
                                              to_char(round((l_end_dttm -
                                                            l_start_dttm) * 1440,
                                                            2),
                                                      'fm999,990.00') ||
                                              ' mins.');

    end;

    procedure insert_rcoa_consumption_hist(p_tran_no   in number,
                                           p_sa_id     in varchar2,
                                           p_bill_date in date) is
    begin
        begin
            insert into bp_consumption_hist
                (tran_no, rdg_date, consumption)
                (select p_tran_no, trunc(rdg_date), sum(consumption)
                 from   (select distinct bs.end_dt rdg_date,
                                         bsq.bill_sq consumption
                         from   ci_bseg bs, ci_bseg_sq bsq
                         where  bs.bseg_id = bsq.bseg_id
                         and    bsq.sqi_cd = rpad('CMBKWHT', 8)
                         and    bs.bseg_stat_flg in ('50', '70')
                         and    bs.sa_id = p_sa_id
                         and    bs.end_dt <= p_bill_date
                         order  by bs.end_dt desc)
                 where  rownum <= 13
                 group  by trunc(rdg_date));
        exception
            when others then
                dbms_application_info.set_action('Error Encountered.');
                raise_application_error(-20130, sqlerrm);
        end;
    end insert_rcoa_consumption_hist;

    function get_rcoa_current_bill_amt(p_bill_id in varchar2,
                                       p_sa_id   in varchar2) return number as
        l_current_bill_amt number;
    begin
        begin
            select nvl(sum(calc.calc_amt), 0)
            into   l_current_bill_amt
            from   ci_bseg bs, ci_sa sa, ci_sa_type st, ci_bseg_calc calc
            where  bs.sa_id = sa.sa_id
            and    st.sa_type_cd = sa.sa_type_cd
            and    bs.bseg_id = calc.bseg_id
            and    bs.bseg_stat_flg in ('50', '70') -- Frozen/OK
            and    bs.bill_id = p_bill_id
            and    trim(st.dst_id) like 'A/R-ELEC%'
            and    sa.sa_type_cd not like 'NET-E%'
            and    trim(st.bill_seg_type_cd) in ('SP-RATED', 'NOSP-RAT');
        exception
            when others then
                log_error('Getting current billed amount.',
                          sqlerrm,
                          null,
                          null,
                          p_bill_id,
                          p_sa_id,
                          null);
                l_current_bill_amt := 0;
        end;

        l_current_bill_amt := l_current_bill_amt + get_lpc(p_bill_id);

        return(l_current_bill_amt);
    end get_rcoa_current_bill_amt;

    procedure insert_rcoagen_bp_details(p_tran_no in number,
                                        p_bill_id in varchar2) as
        l_errmsg varchar2(500);

        l_sa_id varchar2(10);

        l_kwh number;

        l_bcq           number := 0;
        l_bcq_rate      number;
        l_bcq_line_rate varchar2(300);

        l_imbalance           number := 0;
        l_imbalance_rate      number;
        l_imbalance_line_rate varchar2(300);

        l_vat_gen number := 0;
    begin
        begin
            l_errmsg := 'getting rcoa generation sa_id';

            select bs.sa_id
            into   l_sa_id
            from   ci_bseg bs, ci_sa sa, ci_sa_type st
            where  bs.sa_id = sa.sa_id
            and    st.sa_type_cd = sa.sa_type_cd
            and    bs.bseg_stat_flg in ('50', '70') -- Frozen/OK
            and    bs.bill_id = p_bill_id
            and    trim(st.dst_id) like 'A/R-ELEC%'
            and    sa.sa_type_cd not like 'NET-E%'
            and    sa.sa_type_cd like 'RCOALRES%'
            and    trim(st.bill_seg_type_cd) in ('SP-RATED', 'NOSP-RAT');
        end;

        l_errmsg := 'getting calc amounts';

        for l_cur in (select cl.uom_cd,
                             cl.tou_cd,
                             nvl(cl.calc_amt, 0) calc_amt,
                             cl.base_amt,
                             cl.sqi_cd,
                             cl.descr_on_bill
                      from   ci_bseg_calc_ln cl, ci_bseg_calc bc, ci_bseg bs
                      where  bs.bseg_id = bc.bseg_id
                      and    bc.bseg_id = cl.bseg_id
                      and    bc.header_seq = cl.header_seq
                      and    bc.header_seq = 1
                      and    bs.bseg_stat_flg in ('50', '70')
                      and    bs.bill_id = p_bill_id
                      and    bs.sa_id = l_sa_id
                      and    prt_sw = 'Y'
                      order  by rc_seq)
        loop
            if l_cur.descr_on_bill =
               'Generation Charge Peak Off Peak - BCQ'
            then
                l_bcq := l_bcq + l_cur.calc_amt;
            elsif l_cur.descr_on_bill = 'VAT Generation - Total'
            then
                l_vat_gen := l_vat_gen + l_cur.calc_amt;
            elsif l_cur.descr_on_bill like 'Generation Charge -%'
            then
                l_imbalance := l_imbalance + l_cur.calc_amt;
            end if;
        end loop;

        begin
            l_errmsg := 'getting kwh consumption';

            select bill_sq
            into   l_kwh
            from   ci_bseg_sq sq, ci_bseg bseg
            where  sq.bseg_id = bseg.bseg_id
            and    sqi_cd = 'CMBKWHT'
            and    bseg.bseg_stat_flg in ('50', '70')
            and    bseg.bill_id = p_bill_id
            and    bseg.sa_id = l_sa_id;
        end;

        l_errmsg := 'line rate for bcq';
        l_bcq_rate := l_bcq / l_kwh;
        l_bcq_line_rate := to_char(l_bcq_rate, 'fm0.0999999999') || '/kWh';

        l_errmsg := 'line rate for imbalance';
        l_imbalance_rate := l_imbalance / l_kwh;
        l_imbalance_line_rate := to_char(l_imbalance_rate, 'fm0.0999999999') ||
                                 '/kWh';

        l_errmsg := 'inserting details';

        insert into bp_details
            (tran_no, line_code, line_rate, line_amount)
        values
            (p_tran_no, 'GEN-RCOAHDR', null, null);

        insert into bp_details
            (tran_no, line_code, line_rate, line_amount)
        values
            (p_tran_no, 'GEN-RCOAPOP', l_bcq_line_rate, l_bcq);

        insert into bp_details
            (tran_no, line_code, line_rate, line_amount)
        values
            (p_tran_no, 'GEN-RCOAIMB', l_imbalance_line_rate, l_imbalance);

        insert into bp_details
            (tran_no, line_code, line_rate, line_amount)
        values
            (p_tran_no, 'VAT-GENRCOA', null, l_vat_gen);
    exception
        when others then
            log_error('INSERT_RCOAGEN_BP_DETAILS',
                      sqlerrm,
                      l_errmsg,
                      'BP_DETAILS',
                      null,
                      null,
                      null);
            raise_application_error(-20171,
                                    p_bill_id || ' ' || l_errmsg || '-' ||
                                    sqlerrm);
    end insert_rcoagen_bp_details;

    procedure adjust_rcoa_meter_details(p_tran_no     in number,
                                        p_kwhr_cons   in number,
                                        p_kvar_cons   in number,
                                        p_demand_cons in number) as
    begin
        update bp_meter_details
        set    prev_kwhr_rdg   = 0,
               curr_kwhr_rdg   = p_kwhr_cons,
               reg_kwhr_cons   = p_kwhr_cons,
               prev_demand_rdg = 0,
               curr_demand_rdg = p_demand_cons,
               reg_demand_cons = p_demand_cons,
               prev_kvar_rdg   = 0,
               curr_kvar_rdg   = p_kvar_cons,
               reg_kvar_cons   = p_kvar_cons
        where  tran_no = p_tran_no;
    end adjust_rcoa_meter_details;

    procedure extract_bills_rcoa(p_batch_cd  in varchar2,
                                 p_batch_nbr in number,
                                 p_du_set_id in number,
                                 p_thread_no in number default 1,
                                 p_first_row in number default null,
                                 p_last_row  in number default null,
                                 p_bill_id   in varchar2 default null) is
        --Version History
        /*--------------------------------------------------------
           v1.4.1 07-APR-2017 AOCARCALLAS
           Remarks : To query first ebill_statement_accounts if has data else ebill_accounts.
                     -- tag for_ebill_account
        */
        --------------------------------------------------------
        cursor bill_routes_cur is
            select *
            from   (select dense_rank() over(order by br.rowid) row_number,
                           br.batch_cd,
                           br.batch_nbr,
                           br.bill_id,
                           br.entity_name1 customer_name,
                           br.address1,
                           br.address2,
                           br.address3,
                           br.city,
                           trim(b.bill_cyc_cd) billing_batch_no,
                           trunc(b.win_start_dt, 'MONTH') bill_month,
                           b.bill_dt,
                           b.due_dt,
                           trim(bchar.char_val) bill_color, -- decode(substr(br.batch_cd, -1), 'G', 'GREEN', 'RED') bill_color,
                           b.acct_id acct_no,
                           b.complete_dttm,
                           br.no_batch_prt_sw,
                           b.alt_bill_id
                    from   ci_bill_routing br, ci_bill b, ci_bill_char bchar
                    where  br.bill_id = b.bill_id
                    and    b.bill_id = bchar.bill_id
                    and    b.bill_stat_flg = 'C'
                    and    br.bill_rte_type_cd in ('POSTAL', 'POSTAL2')
                    and    bchar.char_type_cd = 'BILLIND '
                    and    bchar.seq_num = 1 --only the first entry in the bill characteristics
                    and    br.seqno = 1 -- just get the first entry in the bill routing
                    and    br.batch_cd = rpad(p_batch_cd, 8)
                    and    br.batch_nbr = p_batch_nbr
                    and    b.bill_id = nvl(p_bill_id, b.bill_id) --and    not exists (select null from bp_headers where bill_no = b.bill_id)
                    )
            where  row_number >= nvl(p_first_row, 1)
            and    row_number <= nvl(p_last_row, 1000000000);

        type br_tab_type is table of bill_routes_cur%rowtype index by binary_integer;

        l_br  br_tab_type;
        l_row pls_integer;

        l_du_set_id  number;
        l_total_recs number;
        l_curr_rec   number := 0;

        l_bph bp_headers%rowtype;

        l_main_sa_id   ci_sa.sa_id%type;
        l_main_sa_dt   date;
        l_main_prem_id ci_sa.char_prem_id%type;

        l_bill_amt       bp_headers.bill_amt%type;
        l_estimate_note  varchar2(20);
        l_other_bseg_amt number;
        l_cmdm_amt       number;

        l_start_dttm    date;
        l_end_dttm      date;
        l_ebill_only_sw char(1);
        l_alt_bill_id   varchar2(20);
        l_txt_only      varchar2(1);
        l_bd_amt        number; --03/06/2024
    begin
        -- update the batch control
        -- increment the batch number so that the next extract will be
        -- grouped under a new batch number
        if p_bill_id is null
        then
            begin
                update ci_batch_ctrl
                set    next_batch_nbr = next_batch_nbr + 1
                where  batch_cd = rpad(p_batch_cd, 8)
                and    next_batch_nbr = p_batch_nbr;

                -- commit right away, so other threads will not be waiting for the
                -- lock on the record to be released
                commit;
            exception
                when others then
                    log_error('Updating Batch Control',
                              sqlerrm,
                              null,
                              'CI_BATCH_CTRL',
                              p_batch_cd,
                              p_batch_nbr,
                              p_thread_no);
                    raise_application_error(-20002, sqlerrm);
            end;
        end if;

        l_start_dttm := sysdate;
        dbms_application_info.set_module('BPX:' ||
                                         to_char(l_start_dttm,
                                                 'hh24:mi:ss'),
                                         'Extracting Bills');

        dbms_application_info.set_client_info('TRD-' ||
                                              to_char(p_thread_no, 'fm00') ||
                                              ': Initializing please wait...');

        -- count total rows to process
        if p_bill_id is not null
        then
            l_total_recs := 1;
        elsif p_first_row is not null and p_last_row is not null
        then
            l_total_recs := (p_last_row - p_first_row) + 1;
        else
            l_total_recs := get_extract_bill_count(p_batch_cd, p_batch_nbr);
        end if;

        dbms_application_info.set_client_info('TRD-' ||
                                              to_char(p_thread_no, 'fm00') ||
                                              ': Total Records - ' ||
                                              to_char(l_total_recs,
                                                      'fm999,999,999'));

        open bill_routes_cur;

        loop
            fetch bill_routes_cur bulk collect
                into l_br limit 1000;

            l_row := l_br.first;

            while (l_row is not null)
            loop
                -- intialize bp_header record
                l_bph := null;

                l_curr_rec := l_curr_rec + 1;

                dbms_application_info.set_client_info('TRD-' ||
                                                      to_char(p_thread_no,
                                                              'fm00') || ': ' ||
                                                      to_char(l_curr_rec) || '/' ||
                                                      to_char(l_total_recs) || ' ' ||
                                                      to_char(ceil((l_curr_rec /
                                                                   l_total_recs) * 100)) || '% ');

                l_main_sa_id := null;
                l_main_sa_dt := to_date('01011900', 'mmddyyyy');
                l_main_prem_id := null;

                l_estimate_note := null;
                l_bph.overdue_amt := null;
                l_bph.overdue_bill_count := null;
                l_bph.bill_amt := null;

                for r2 in (select sa.sa_id,
                                  trim(st.dst_id) dst_id,
                                  trim(st.bill_seg_type_cd) bill_seg_type_cd,
                                  bs.end_dt,
                                  bs.est_sw,
                                  sa.char_prem_id
                           from   ci_bseg bs, ci_sa sa, ci_sa_type st
                           where  bs.sa_id = sa.sa_id
                           and    st.sa_type_cd = sa.sa_type_cd
                           and    bs.bseg_stat_flg in ('50', '70') -- Frozen/OK
                           and    bs.bill_id = l_br(l_row).bill_id
                           and    trim(st.dst_id) = 'A/R-ELEC'
                           and    sa.sa_type_cd not like 'NET-E%'
                                 --and    sa.sa_type_cd not like 'RCOA_DU%'
                                 --and    sa.sa_type_cd like 'RCOALRES%'
                           and    trim(st.bill_seg_type_cd) in
                                  ('SP-RATED', 'NOSP-RAT'))
                loop
                    if r2.end_dt > l_main_sa_dt
                    then
                        l_main_sa_dt := r2.end_dt;
                        l_main_sa_id := r2.sa_id;
                        l_main_prem_id := r2.char_prem_id;

                        /*if l_br(l_row).bill_month is null
                        then
                           l_br(l_row).bill_month := trunc(r2.end_dt, 'MONTH');
                        end if;*/

                        l_br(l_row).bill_month := trunc(r2.end_dt, 'MONTH');

                        -- determine if bill is estimated
                        if r2.est_sw = 'Y'
                        then
                            l_bph.bill_type := 'E'; -- estimated
                            l_estimate_note := '(ESTIMATE)';
                        else
                            l_bph.bill_type := 'R'; -- regular
                        end if;

                        l_bill_amt := get_rcoa_current_bill_amt(l_br(l_row).bill_id,
                                                                r2.sa_id);

                        -- get current bill amount
                        l_bph.bill_amt := nvl(l_bph.bill_amt, 0) +
                                          l_bill_amt;

                        l_bph.overdue_amt := 0;

                        --if l_br(l_row).bill_color = 'RED'
                        --then
                        -- get over due amount
                        l_bph.overdue_amt := nvl(l_bph.overdue_amt, 0) +
                                             get_overdue_amt90(l_br(l_row).bill_id);

                        if l_bph.overdue_amt <= 0
                        then
                            l_br(l_row).bill_color := 'GREEN';
                        else
                            --l_bph.overdue_bill_count := 1;
                            l_bph.overdue_bill_count := get_overdue_bill_cnt(r2.sa_id,
                                                                             l_br(l_row).bill_dt,
                                                                             l_bph.overdue_amt);
                        end if;

                        --end if;

                        l_bph.par_kwhr := get_par_kwh(l_br(l_row).bill_id);
                        l_bph.par_month := get_par_month(r2.sa_id,
                                                         r2.end_dt);
                    end if;
                end loop;

                -- if there is  a billed Electric SA, dont proceed
                if l_bph.bill_amt is not null
                then
                    -- *** This section gets the bill's pertinent info ***
                    -- *** or the not so critical data

                    -- get crc
                    l_bph.crc := get_crc(l_br(l_row).acct_no);

                    -- retrieve the premise address
                    retrieve_premise_address(l_main_prem_id,
                                             l_bph.premise_add1,
                                             l_bph.premise_add2,
                                             l_bph.premise_add3);

                    -- get the rate schedule of the account being billed
                    retrieve_rate_schedule(l_br(l_row).bill_id,
                                           l_main_sa_id,
                                           l_bph.rate_schedule,
                                           l_bph.rate_schedule_desc);

                    -- get default courier code based on the rate schedule
                    l_bph.courier_code := 'P';

                    -- get area code, derived from bill routing city
                    l_bph.area_code := get_area_code(l_br(l_row).city);

                    -- get the last payment event, date and amount
                    retrieve_last_payment(l_br                     (l_row).acct_no,
                                          l_br                     (l_row).bill_dt,
                                          l_bph.last_payment_date,
                                          l_bph.last_payment_amount);

                    -- get book no. or service route
                    l_bph.book_no := get_book_no(l_main_sa_id);

                    -- get delivery sequence
                    l_bph.new_seq_no := get_bdseq(l_br(l_row).acct_no);

                    -- get messenger code
                    l_bph.messenger_code := get_bdmsgr(l_br(l_row).acct_no);

                    -- get bill message
                    l_bph.message_code := get_bill_message(l_br(l_row).bill_id);

                    -- *** This section retrieves the critical info of the bill

                    -- get billed consumptions from bseg_sq
                    l_bph.billed_kwhr_cons := get_bill_sq(l_br(l_row).bill_id,
                                                          l_main_sa_id,
                                                          'CMBKWHT');
                    l_bph.billed_kvar_cons := get_bill_sq(l_br(l_row).bill_id,
                                                          l_main_sa_id,
                                                          'BILLKVAR');
                    l_bph.billed_demand_cons := get_bill_sq(l_br(l_row).bill_id,
                                                            l_main_sa_id,
                                                            'BILLKW');
                    l_bph.power_factor_value := get_bill_sq(l_br(l_row).bill_id,
                                                            l_main_sa_id,
                                                            'BILLPF');

                    -- get net bill amount
                    l_bph.total_amt_due := get_net_bill_amt2(l_br(l_row).bill_id);

                    -- get billing cycle
                    l_bph.billing_batch_no := l_br(l_row).billing_batch_no;

                    if trim(l_bph.billing_batch_no) is null
                    then
                        l_bph.billing_batch_no := get_billing_cycle(l_br(l_row).acct_no);
                    end if;

                    -- tag for_ebill_account
                    begin
                        l_ebill_only_sw := 'N';

                        select decode(print_sw, 'N', 'Y', 'N')
                        into   l_ebill_only_sw
                        from   ebill_statement_accounts
                        where  acct_id = l_br(l_row).acct_no
                        and    status = 'ACTIVE';
                    exception
                        when others then
                            begin
                                select 'Y'
                                into   l_ebill_only_sw
                                from   ebill_accounts
                                where  acct_id = l_br(l_row).acct_no
                                and    incld_in_batch_pr_sw = 'N'
                                and    enabled = 1;
                            exception
                                when no_data_found then
                                    l_ebill_only_sw := 'N';
                                when too_many_rows then
                                    l_ebill_only_sw := 'Y';
                                when others then
                                    l_ebill_only_sw := 'N';
                            end;
                    end;

                    -- get tag for ebill_txt_account
                    l_txt_only := get_text_only_tag(l_br(l_row).acct_no); -->> v1.3.9.5

                    l_bph.tin := get_tin(l_br(l_row).acct_no);

                    declare
                        l_temp_message_code varchar2(90);
                    begin
                        l_temp_message_code := get_bill_messages(l_br(l_row).bill_id);

                        if l_temp_message_code is not null
                        then
                            l_bph.message_code := l_temp_message_code;
                        end if;
                    end;

                    --getting CAS Sequence
                    l_alt_bill_id := l_br(l_row).alt_bill_id;

                    -- now create the header record for the bill
                    begin
                        insert into bp_headers
                            (du_set_id,
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
                             messenger_code,
                             par_month,
                             par_kwhr,
                             no_batch_prt_sw,
                             ebill_only_sw,
                             tin,
                             complete_date,
                             alt_bill_id,
                             txt_only)
                        values
                            (p_du_set_id,
                             l_br(l_row).batch_cd,
                             l_br(l_row).batch_nbr,
                             l_br(l_row).bill_id,
                             l_br(l_row).customer_name,
                             l_bph.premise_add1,
                             l_bph.premise_add2,
                             l_bph.premise_add3,
                             l_br(l_row).address1,
                             l_br(l_row).address2,
                             l_br(l_row).address3,
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
                             l_bph.messenger_code,
                             l_bph.par_month,
                             l_bph.par_kwhr,
                             l_br(l_row).no_batch_prt_sw,
                             l_ebill_only_sw,
                             l_bph.tin,
                             l_br(l_row).complete_dttm,
                             l_alt_bill_id,
                             l_txt_only)
                        returning tran_no into l_bph.tran_no;
                    exception
                        when dup_val_on_index then
                            log_error('Insert to headers',
                                      sqlerrm,
                                      'Duplicate Bill ID',
                                      'BP_HEADERS',
                                      p_batch_cd,
                                      p_batch_nbr,
                                      l_br(l_row).bill_id);
                            --raise_application_error(-20202, sqlerrm);

                        when others then
                            log_error('Insert to headers',
                                      sqlerrm,
                                      null,
                                      'BP_HEADERS',
                                      p_batch_cd,
                                      p_batch_nbr,
                                      l_br(l_row).bill_id);

                            dbms_application_info.set_action('Error Encountered.');

                            raise_application_error(-20201, sqlerrm);
                    end;

                    if l_bph.tran_no is not null
                    then
                        -- insert bill message parameters
                        populate_bill_msg_param(l_bph.tran_no,
                                                l_br(l_row).bill_id,
                                                l_bph.messenger_code);

                        -- insert meter details
                        old_insert_meter_details(l_bph.tran_no,
                                                 l_br         (l_row).bill_id,
                                                 l_main_sa_id,
                                                 l_br         (l_row).bill_dt);

                        -- adjust rcoa billed readings
                        adjust_rcoa_meter_details(l_bph.tran_no,
                                                  l_bph.billed_kwhr_cons,
                                                  l_bph.billed_kvar_cons,
                                                  l_bph.billed_demand_cons);

                        -- insert consumption history
                        insert_rcoa_consumption_hist(l_bph.tran_no,
                                                     l_main_sa_id,
                                                     l_br(l_row).bill_dt);

                        --inserting rcoas generation details
                        insert_rcoagen_bp_details(l_bph.tran_no,
                                                  l_br(l_row).bill_id);

                        -- insert the bill's detail lines
                        insert_bp_details(l_bph.tran_no,
                                          l_br(l_row).bill_id,
                                          l_main_sa_id);

                        --insert_rcoa_bp_details
                        --(l_bph.tran_no
                        --,l_br(l_row).bill_id);

                        -- insert bir 2013 requirements
                        populate_bp_bir_2013(l_bph.tran_no,
                                             l_br(l_row).bill_id);
                                             
                        
                        -- insert additional info for the bill's detail lines
                        add_detail_line(l_bph.tran_no,
                                        'OVERDUE',
                                        null,
                                        l_bph.overdue_amt);

                        add_detail_line(l_bph.tran_no,
                                        'CURBIL',
                                        to_char(l_br(l_row).bill_month,
                                                'fmMONTH YYYY') ||
                                        l_estimate_note,
                                        l_bph.bill_amt);

                        add_detail_line(l_bph.tran_no,
                                        'OUTAMT',
                                        null,
                                        l_bph.total_amt_due);
                                        


                        if l_br(l_row).bill_color = 'GREEN'
                        then
                            declare
                                l_apay_code   bp_detail_codes.code%type;
                                l_apay_src_cd ci_acct_apay.apay_src_cd%type;
                            begin
                                /*select code
                                into   l_apay_code
                                from   (select apay_src_cd, code
                                        from   ci_acct_apay apay,
                                               bp_detail_codes bp
                                        where  apay.apay_src_cd =
                                               bp.ccnb_descr_on_bill
                                        and    apay.acct_id = l_br(l_row).acct_no
                                        and    apay.end_dt is null)
                                where  rownum = 1;
                                */
                                select apay_src_cd
                                into   l_apay_src_cd
                                from   ci_acct_apay
                                where  acct_id = l_br(l_row).acct_no
                                and    end_dt is null;

                                select code
                                into   l_apay_code
                                from   bp_detail_codes
                                where  ccnb_descr_on_bill = l_apay_src_cd;

                                add_detail_line(l_bph.tran_no,
                                                l_apay_code,
                                                null,
                                                null);
                            exception
                                when no_data_found then
                                    add_detail_line(l_bph.tran_no,
                                                    'CCBNOTICE',
                                                    to_char(l_br(l_row).due_dt,
                                                            'MM/DD/YYYY'),
                                                    null);
                            end;
                        else
                            add_detail_line(l_bph.tran_no,
                                            'CCBREDNOTICE',
                                            null,
                                            null);
                        end if;

                        -- add info on last payment date and amount
                        if l_bph.last_payment_date is not null
                        then
                            add_detail_line(l_bph.tran_no,
                                            'CCBNOTICE1',
                                            'LAST PAYMENT  -  ' ||
                                            to_char(l_bph.last_payment_date,
                                                    'fmMONTH DD, YYYY') ||
                                            '  -  ' ||
                                            to_char(l_bph.last_payment_amount,
                                                    'fm9,999,999,990.00'),
                                            null);
                        end if;

                        l_other_bseg_amt := 0;

                        -- insert Payment Arrangements and such
                        if l_bph.total_amt_due <>
                           l_bph.bill_amt + l_bph.overdue_amt
                        then
                            insert_other_bseg(l_bph.tran_no,
                                              l_br(l_row).bill_id);
                            l_other_bseg_amt := get_other_bseg_amt(l_br(l_row).bill_id);
                        end if;
                        
                        -- insert BD bseg amt
                        if l_bph.total_amt_due <>
                           l_bph.bill_amt + l_bph.overdue_amt
                        then
                           insert_bd_bseg(l_bph.tran_no,
                                          l_br(l_row).bill_id);
                           l_other_bseg_amt := get_bd_bseg_amt(l_br(l_row).bill_id);
                        end if;

                        -- insert cmdm amount
                        l_cmdm_amt := l_bph.total_amt_due -
                                      (l_bph.bill_amt + l_other_bseg_amt +
                                      l_bph.overdue_amt);

                        if nvl(l_cmdm_amt, 0) <> 0
                        then
                            insert_adj(l_bph.tran_no,
                                       l_br(l_row).bill_id,
                                       l_main_sa_id,
                                       l_cmdm_amt);
                        end if;

                        /*if l_cmdm_amt < 0
                        then
                           add_detail_line (
                              l_bph.tran_no,
                              'nCCBADJ',
                              null,
                              l_cmdm_amt
                              );
                        elsif l_cmdm_amt > 0
                        then
                           add_detail_line (
                              l_bph.tran_no,
                              'pCCBADJ',
                              null,
                              l_cmdm_amt
                              );
                        end if;*/

                        if ((l_bph.rate_schedule_desc like '%TOU') or
                           (l_bph.rate_schedule like '%-IR-%'))
                        then
                            adjust_tou_presentation(l_bph.tran_no,
                                                    l_br(l_row).bill_id,
                                                    l_main_sa_id);
                        end if;
                        --remove_zero_line_amt
                        remove_zero_line_amt(l_bph.tran_no); --gperater 09/13/2023 v1.4.0
                    end if;
                end if;

                l_row := l_br.next(l_row);
            end loop;

            exit when bill_routes_cur%notfound;
        end loop; -- driving loop;

        close bill_routes_cur;

        commit;

        if p_bill_id is null
        then
            update_adjocs_alt_bill_id(trunc(sysdate), trunc(sysdate));
        end if;

        l_end_dttm := sysdate;
        dbms_application_info.set_action(to_char(l_end_dttm, 'hh24:mi:ss'));
        dbms_application_info.set_client_info('TRD-' ||
                                              to_char(p_thread_no, 'fm00') ||
                                              ': Done in ' ||
                                              to_char(round((l_end_dttm -
                                                            l_start_dttm) * 1440,
                                                            2),
                                                      'fm999,990.00') ||
                                              ' mins.');
    end extract_bills_rcoa;

    procedure extract_multi_threaded(p_batch_cd     in varchar2,
                                     p_batch_nbr    in number,
                                     p_thread_count in number) is
        l_du_set_id       number;
        l_total_recs      number;
        l_recs_per_thread number;
    begin
        begin
            select bph_du_set_ids.nextval into l_du_set_id from dual;
        exception
            when others then
                raise_application_error(-20001, sqlerrm);
        end;

        begin
            select count(*)
            into   l_total_recs
            from   ci_bill_routing br, ci_bill b
            where  br.bill_id = b.bill_id
            and    br.batch_cd = rpad(p_batch_cd, 8)
            and    br.batch_nbr = p_batch_nbr
            and    b.bill_stat_flg = 'C'
            and    not exists
             (select null from bp_headers where bill_no = b.bill_id);
        end;

        if l_total_recs > 0
        then
            l_recs_per_thread := ceil(l_total_recs / p_thread_count);

            for r in 0 .. p_thread_count - 1
            loop
                dbms_job.isubmit(901 + r,
                                 'bp_extract_pkg.extract_bills(''' ||
                                 p_batch_cd || ''',' ||
                                 to_char(p_batch_nbr) || ',' ||
                                 to_char(l_du_set_id) || ',' ||
                                 to_char(r + 1) || ',' ||
                                 to_char((r * l_recs_per_thread) + 1) || ',' ||
                                 to_char((r * l_recs_per_thread) +
                                         l_recs_per_thread) || ');',
                                 sysdate);
                commit;
            end loop;
        end if;
    end;

end bp_extract_pkg;
