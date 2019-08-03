#!/bin/bash
#
# optimize tables
#

for t in mis_user_info \
t_user_info \
user_device \
user_lesson_device \
user_ping_test \
www_verify_codes \
erp_clients \
erp_clients_history \
erp_contract \
erp_contract_orders \
client_data_pool \
client_sea \
erp_application_doc \
erp_application_flow \
erp_client_follow \
erp_client_channel \
erp_client_cr \
erp_client_event \
erp_client_family \
erp_homework \
erp_notification \
erp_order_flow \
erp_teacher_schedule \
etage_info \
etage_keywords \
etage_warning \
lesson_comment \
mis_login_log \
mis_oper_log \
mobile_info \
server_trail_and_voice \
server_lesson_voice \
server_lesson_log \
sms_notification \
student_notification \
erp_lesson_application \
erp_lesson_book_files \
erp_lesson_docs \
erp_lesson_flow \
erp_lesson_plan \
erp_lesson_application_plan \
erp_lessons
do
    if [[ ! $t =~ ^erp ]];then
        #date
        echo "mysql -A yimi -e 'optimize table ${t};'"
        #mysql -A yimi -e "optimize table ${t};"
        #echo
    fi
done
