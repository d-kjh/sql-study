ALTER TABLE membership_tier
ADD CONSTRAINT uq_sort_order UNIQUE (sort_order);

ALTER TABLE user
ADD CONSTRAINT uq_email_phone UNIQUE (email, phone);

ALTER TABLE theater
ADD CONSTRAINT uq_region_name UNIQUE (region, name);

ALTER TABLE employee
ADD CONSTRAINT uq_theater_id_name_phone UNIQUE (theater_id, name, phone);

ALTER TABLE screen
ADD CONSTRAINT uq_theater_id_name UNIQUE (theater_id, name);

ALTER TABLE seat
ADD CONSTRAINT uq_screen_id_row_label_col_no UNIQUE (screen_id, row_label, col_no);

ALTER TABLE reservation_seat
ADD CONSTRAINT uq_schedule_id_seat_id UNIQUE (schedule_id, seat_id);

ALTER TABLE store_item
ADD CONSTRAINT uq_store_item_code_item_name UNIQUE (store_item_code, item_name);

ALTER TABLE event
ADD CONSTRAINT uq_event_code_event_title_start_date UNIQUE (event_code, event_title, start_date);

ALTER TABLE user
ADD CONSTRAINT uq_card_num UNIQUE (card_num);