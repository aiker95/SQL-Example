CREATE OR REPLACE FUNCTION human.human_obj(filters text[], parametrs text[], limit_ integer DEFAULT 100, offset_ integer DEFAULT 0)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
declare 
sql_query varchar;
select_human varchar;
select_phone varchar;
select_email varchar;
select_telegram varchar;
select_address varchar;
select_work varchar;
select_education varchar;
select_hdoc varchar;
from_human_1 varchar;
from_phone_1 varchar;
from_email_1 varchar;
from_telegram_1 varchar;
from_address_1 varchar;
from_work_1 varchar;
from_education_1 varchar;
from_hdoc_1 varchar;
from_human_2 varchar;
from_phone_2 varchar;
from_email_2 varchar;
from_telegram_2 varchar;
from_address_2 varchar;
from_work_2 varchar;
from_education_2 varchar;
from_hdoc_2 varchar;
sql_where_1 varchar;
sql_where_2 varchar;
sql_filter varchar;
sql_group_by varchar;
phone_general varchar;
email_general varchar;

BEGIN


 select_human = '
SELECT json_agg(row) as human_obj from ( 

select  human_uuid, snils, inn, last_name, first_name, father_name,  gender, birthday ';
	
select_phone = ',	json_agg(distinct(jsonb_build_object(''phone_link_uuid'', phone_link_uuid, ''prefix'', prefix, ''a_number'', a_number, ''extra'', extra, ''cellular'', cellular, 
	''phone_general'', phone_general, ''phone_description'', phone_description, ''phone_verified'', phone_verified, ''phone_verified'', phone_verified))) as phone ';
	
select_email = '	 ,json_agg(distinct(jsonb_build_object(''email_link_uuid'', email_link_uuid, ''email'', email, 
	''email_general'', email_general, ''email_description'', email_description, ''email_verified'', email_verified, ''email_verified'', email_verified))) as email';	
	
select_telegram	 = ', json_agg(distinct(jsonb_build_object(''tgm_id'', tgm_id, ''nickname'', nickname, ''tgm_general'', tgm_general))) as telegram ';
	

select_address ='	,json_agg(distinct(jsonb_build_object(''address_link_uuid'', address_link_uuid, ''address'', address, ''house_number'', house_number, ''build_number'',build_number, 
	''struct_number'', struct_number, ''vladenie'',vladenie, ''litera'',litera,  
	''apartment'',apartment, ''address_type'' ,  address_type
			))) as address 	';
	
select_work = ' ,json_agg(distinct(jsonb_build_object(''work_organization_uuid'', work_organization_uuid, ''work_organization_name'', work_organization_name, ''work_organization_fullname'', work_organization_fullname, 
             ''human_staff_link_uuid'', human_staff_link_uuid, ''work_position'', work_position, ''rate'', rate, ''subdivision_name'', subdivision_name
             ))) as work';
select_education =',json_agg(distinct(jsonb_build_object(''education_organization_name'', education_organization_name, ''education_type'', education_type, ''education_date_begin'', education_date_begin, ''education_date_end'', education_date_end))) as education ';
             
select_hdoc =   ' ,json_agg(distinct(jsonb_build_object(''hdoc_uuid'', hdoc_uuid, ''serie'', serie, ''number'', number, ''date_get'', date_get, ''by_organization'', by_organization, ''hdoc_type_name'', hdoc_type_name
         ))) as hdoc';
	
from_human_1 = 	' from (

SELECT hum.uuid as human_uuid, hum.snils, hum.inn, hum.last_name, hum.first_name, hum.father_name,  hum.gender, hum.birthday';
 
from_phone_1   = ',phone_link.uuid as phone_link_uuid, prefix , a_number, phone_link.extra, cellular,  
          phone_link.general as phone_general,  phone_link.description as phone_description, phone_link.verified as phone_verified,  phone_link.contact_type as phone_contact_type';
            
from_email_1   = ', email_link.uuid as email_link_uuid,  email,  
         email_link.general as email_general, email_link.description as email_description, email_link.verified as email_verified, email_link.contact_type as email_contact_type' ;
         
from_telegram_1 = ', tgm_users.tgm_id, tgm_users.nickname,  tgm_users.general as tgm_general ';
       
from_address_1 = ' ,  address_link.uuid as address_link_uuid,  address.address,  address.house_number, address.build_number, address.struct_number, address.vladenie, address.litera, 
         address_link.apartment,  address_link.address_type';
         
from_work_1 =        ' ,  organization.uuid as work_organization_uuid, organization.name as work_organization_name, organization.fullname as work_organization_fullname, 
         human_staff_link.uuid as human_staff_link_uuid, job_post.name as work_position,  rate,  subdivision.law_name as subdivision_name';
        
from_education_1 = '  , education_organization.name as education_organization_name, education.education_type, education.date_begin as education_date_begin, education.date_end as education_date_end';
         
from_hdoc_1 = ' , hdoc.uuid as hdoc_uuid, hdoc.serie,  hdoc.number,  hdoc.date_get,  hdoc.by_organization,  doc_type.type_name as hdoc_type_name ';
            
from_human_2 =  'FROM human.human as hum  ';
            
            -- Телефоны человека (выводится всегда)
phone_general = ' and phone_link.general = true';			
from_phone_2   = ' left JOIN human.phone_link          ON human.phone_link.human_uuid     = hum.uuid                                   AND human.phone_link.deleted_at is null' || phone_general ||' 
            left JOIN characteristic.phone               ON characteristic.phone.uuid                = human.phone_link.phone_uuid                AND characteristic.phone.deleted_at is null     ';
	        -- Email человека (выводится всегда)
email_general = ' and email_link.general = true';
from_email_2   =  ' left JOIN human.email_link          ON human.email_link.human_uuid     = hum.uuid                                   AND human.email_link.deleted_at is null' || email_general || '
            left JOIN characteristic.email               ON characteristic.email.uuid                = human.email_link.email_uuid                AND characteristic.email.deleted_at is null    ';
	       	-- Telegram человека  (выводится всегда)
from_telegram_2 = '	left join telegram.tgm_users on tgm_users.human_uuid = hum.uuid and tgm_users.deleted_at is null and tgm_users.general = true';
	        -- Адреса человека (выводится по запросу)
	    
from_address_2 = '  left join human.address_link on address_link.human_uuid = hum.uuid and address_link.deleted_at is not null
		    left join characteristic.address on address_link.address_uuid = address.uuid and address.deleted_at is not null	        ';    
	        -- Работа человека (выводится по запросу)
from_work_2 = ' left JOIN human.human_staff_link      ON human.human_staff_link.human_uuid = hum.uuid                                   AND human.human_staff_link.deleted_at is null
            left JOIN organization.organization  ON organization.organization.uuid  = human.human_staff_link.organization_uuid     AND organization.organization.deleted_at is null       
	        left join organization.staff on staff_uuid = staff.uuid and staff.deleted_at is null 
          	left join organization.job_post on organization.staff.job_post_uuid = job_post.uuid and job_post.deleted_at is null  
            left join organization.subdivision on subdivision.uuid =        staff.subdivision_uuid';
            -- Образование человека (выводится по запросу)
from_education_2 =  ' left join human.education on education.human_uuid = hum.uuid and education.deleted_at is not null 
            left join characteristic.education_organization on education.edu_organization_uuid = education_organization.uuid and education_organization.deleted_at is not null';
	        -- Документы человека (выводится по запросу)
from_hdoc_2 = ' left join human.hdoc on hdoc.human_uuid = hum.uuid and hdoc.deleted_at is null
      		left join human.doc_type on hdoc.doc_type_uuid = doc_type.uuid and doc_type.deleted_at is null ';
	      	
	      	
sql_where_1 =           ' WHERE hum.deleted_at is null      ) as query ';

sql_where_2 =  ' Where 1=1';
sql_filter = '';
	            
sql_group_by =  '      group by human_uuid, snils, inn, last_name, first_name, father_name,  gender, birthday LIMIT  ' || cast(limit_ as varchar) ||' OFFSET  '  || cast(offset_ as int) || '

)  as row ';
	        
	
	
	
sql_query = select_human || select_phone || select_email || select_telegram || select_address || select_work || select_education || select_hdoc || from_human_1 || from_phone_1 || from_email_1 || from_telegram_1 || from_address_1 || from_work_1 || from_education_1 || from_hdoc_1 || from_human_2 || from_phone_2 || from_email_2 || from_telegram_2 || from_address_2 || from_work_2 || from_education_2 || from_hdoc_2 || sql_where_1 || sql_where_2 || sql_filter || sql_group_by;

 RETURN sql_query;

end;



 $function$
;