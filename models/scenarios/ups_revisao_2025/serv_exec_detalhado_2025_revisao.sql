select
*
from {{ref("serv_exec_detalhado_oper_go_2025_revisao")}}

union all

select * from {{ref("serv_exec_detalhado_siga_2025_revisao")}}