-- <t>reporting_layer.book_score_rank_data</t>
CREATE EXTERNAL TABLE IF NOT EXISTS reporting_layer.book_score_rank_data (
    book_id integer,
    book_title string,
    subject_name string,
    topic_name string,
    language_name string,
    publisher_name string,
    publisher_imprint string,
    author string,
    norm_dtc_revenue double,
    norm_enrollment double,
    norm_bay_read_mins double,
    norm_clicks double,
    publication_date string,
    newness bigint,
    overall_rank bigint,
    athena_timestamp timestamp
) STORED AS PARQUET LOCATION 's3://perlego-reporting-layer-072234025673-eu-west-2/reporting_layer_test/book_score_rank_data/' TBLPROPERTIES ('has_encrypted_data'='false')
;
