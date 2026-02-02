with dummy_source as (
    select * from {{ ref('test_source') }}
)

select
    timestamp_string,
    {{ parse_timestamp('timestamp_string') }} as parsed_timestamp
from dummy_source
