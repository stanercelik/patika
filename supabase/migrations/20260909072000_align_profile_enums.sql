alter table public.profiles drop constraint if exists profiles_gender_check;
alter table public.profiles add constraint profiles_gender_check
  check (gender is null or gender in ('woman', 'man', 'other', 'undisclosed'));

alter table public.profiles drop constraint if exists profiles_age_range_check;
alter table public.profiles add constraint profiles_age_range_check
  check (age_range is null or age_range in ('eighteenToTwentyFour', 'twentyFiveToThirtyFour', 'thirtyFiveToFortyFour', 'fortyFiveToFiftyFour', 'fiftyFivePlus', 'undisclosed'));
