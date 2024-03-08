insert into bpx.bp_detail_codes
    (code,
     description,
     print_priority,
     indent_level,
     regular_desc,
     line_type,
     line_font_att,
     formula_type,
     ccnb_descr_on_bill,
     ccnb_sqi_cd,
     summary_group)
values
    ('BDSA',
     'Bill Deposit',
     1362,
     0,
     null,
     'regular',
     'normal',
     'regular',
     null,
     null,
     null);

commit;
