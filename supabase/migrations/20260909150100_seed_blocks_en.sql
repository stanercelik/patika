-- English block library — v1 engineering draft.
-- These texts intentionally remain unreviewed. Before production release,
-- `select * from public.unreviewed_blocks` must return no rows.

insert into public.blocks
  (id, version, locale, category, technique, goals, phases, difficulty,
   min_duration_sec, max_duration_sec, prerequisites, contraindications,
   breath_pattern, script, audio_tag, reviewed_at)
values
('opening.arrival.en.v1', 1, 'en', 'frame', 'Arrival', array['beginning'],
 array['relief','awareness','skill','behavior','closing'], 1, 50, 110,
 '{}', '{}', null,
 $json$[
   {"type":"slot","name":"step_opening"},
   {"type":"silence","breaths":1},
   {"type":"fixed","text":"Let yourself settle where you are sitting or lying down. If closing your eyes feels right, you can close them. Otherwise, rest your gaze on one point."},
   {"type":"silence","breaths":1,"landOn":"exhale"}
 ]$json$, null, NULL),

('breath.awareness.en.v1', 1, 'en', 'foundation', 'Breath awareness',
 array['immediate_tension','before_sleep','beginning'], array['relief','awareness'],
 1, 170, 280, '{}', '{}', null,
 $json$[
   {"type":"slot","name":"technique_bridge"},
   {"type":"fixed","text":"There is no need to change your breath. Let it arrive in its own way."},
   {"type":"silence","breaths":2},
   {"type":"fixed","text":"Notice where you feel it most clearly. At your nose, in your chest, or in your belly."},
   {"type":"silence","breaths":2},
   {"type":"fixed","text":"Now follow the movement on the screen. Breathe in as it opens, and breathe out as it draws in."},
   {"type":"silence","breaths":4,"landOn":"exhale"},
   {"type":"slot","name":"mid_bridge"},
   {"type":"fixed","text":"Let the out-breath take a little longer. There is no hurry."},
   {"type":"silence","breaths":4,"landOn":"exhale"}
 ]$json$, null, NULL),

('breath.extendedExhale.en.v1', 1, 'en', 'foundation', 'Longer out-breath',
 array['immediate_tension','before_sleep'], array['relief'], 1, 180, 300,
 array['breath.awareness.en.v1'], '{}',
 $json${"inhale":4,"hold":0.5,"exhale":7,"rest":0}$json$,
 $json$[
   {"type":"slot","name":"technique_bridge"},
   {"type":"fixed","text":"This time, we will let the out-breath last a little longer. Count to four as you breathe in and seven as you breathe out. The count can be approximate."},
   {"type":"silence","breaths":1},
   {"type":"fixed","text":"Breathe in now. One, two, three, four."},
   {"type":"silence","breaths":3,"landOn":"exhale"},
   {"type":"fixed","text":"Keep the next out-breath easy and unforced."},
   {"type":"silence","breaths":4,"landOn":"exhale"},
   {"type":"slot","name":"mid_bridge"},
   {"type":"silence","breaths":4,"landOn":"exhale"}
 ]$json$, null, NULL),

('breath.box.en.v1', 1, 'en', 'foundation', 'Box breathing',
 array['immediate_tension','focus'], array['relief','skill'], 2, 230, 400,
 array['breath.awareness.en.v1'], array['history_of_panic'],
 $json${"inhale":4,"hold":4,"exhale":4,"rest":4}$json$,
 $json$[
   {"type":"slot","name":"technique_bridge"},
   {"type":"fixed","text":"This pattern has four equal parts. Breathe in for four, hold for four, breathe out for four, and wait for four. If holding feels uncomfortable, leave it out and simply breathe in and out."},
   {"type":"silence","breaths":1},
   {"type":"fixed","text":"Begin when you are ready. The movement on the screen will stay with the rhythm."},
   {"type":"silence","breaths":4},
   {"type":"slot","name":"mid_bridge"},
   {"type":"silence","breaths":4,"landOn":"exhale"}
 ]$json$, null, NULL),

('body.grounding.en.v1', 1, 'en', 'body', 'Grounding',
 array['immediate_tension','disconnection'], array['relief','awareness'], 1, 140, 250,
 '{}', '{}', null,
 $json$[
   {"type":"slot","name":"technique_bridge"},
   {"type":"fixed","text":"Notice where your feet meet the floor, and where your back meets the surface behind you."},
   {"type":"silence","breaths":2},
   {"type":"fixed","text":"Bring your attention to your shoulders. If they can lower, let them. If they do not, noticing is enough."},
   {"type":"silence","breaths":2},
   {"type":"fixed","text":"Notice your jaw and forehead. Give them room to soften if they can."},
   {"type":"silence","breaths":2,"landOn":"exhale"},
   {"type":"fixed","text":"For one moment, sense your body as a whole. Nothing needs to be corrected."},
   {"type":"silence","breaths":3,"landOn":"exhale"}
 ]$json$, null, NULL),

('body.scan.en.v1', 1, 'en', 'body', 'Body scan',
 array['before_sleep','tension'], array['awareness'], 2, 290, 470,
 array['body.grounding.en.v1'], '{}', null,
 $json$[
   {"type":"slot","name":"technique_bridge"},
   {"type":"fixed","text":"We will move attention from your feet upward. At each place, notice what is there without trying to change it."},
   {"type":"silence","breaths":1},
   {"type":"fixed","text":"Feet."},
   {"type":"silence","breaths":2},
   {"type":"fixed","text":"Legs and hips."},
   {"type":"silence","breaths":2},
   {"type":"fixed","text":"Belly and chest. You may notice the breath moving through here."},
   {"type":"silence","breaths":3},
   {"type":"slot","name":"mid_bridge"},
   {"type":"fixed","text":"Shoulders, arms, and hands."},
   {"type":"silence","breaths":2},
   {"type":"fixed","text":"Neck, jaw, and face."},
   {"type":"silence","breaths":3,"landOn":"exhale"}
 ]$json$, null, NULL),

('reflection.notice.en.v1', 1, 'en', 'awareness', 'Naming what is here',
 array['emotional_awareness'], array['awareness','skill'], 2, 170, 290,
 '{}', '{}', null,
 $json$[
   {"type":"slot","name":"technique_bridge"},
   {"type":"fixed","text":"Give a simple name to what is here right now. Tension, tiredness, restlessness, emptiness, or something else."},
   {"type":"silence","breaths":3},
   {"type":"fixed","text":"There is no need to change what you named. Noticing it is enough for today."},
   {"type":"silence","breaths":3},
   {"type":"slot","name":"mid_bridge"},
   {"type":"fixed","text":"If your attention wandered, that is ordinary. Return to the breath when you are ready."},
   {"type":"silence","breaths":3,"landOn":"exhale"}
 ]$json$, null, NULL),

('reflection.distance.en.v1', 1, 'en', 'awareness', 'Making space around a thought',
 array['repeating_thoughts','before_sleep'], array['skill'], 3, 230, 350,
 array['reflection.notice.en.v1'], array['immediate_crisis'], null,
 $json$[
   {"type":"slot","name":"technique_bridge"},
   {"type":"fixed","text":"When a thought arrives, there is no need to push it away. Try adding four words before it: I am having the thought."},
   {"type":"silence","breaths":2},
   {"type":"fixed","text":"Instead of tomorrow will go badly, try I am having the thought that tomorrow will go badly. The thought is still there, with a little space around it."},
   {"type":"silence","breaths":3},
   {"type":"slot","name":"mid_bridge"},
   {"type":"fixed","text":"You can try that with the next thought. If it does not fit, leave it and return to the breath."},
   {"type":"silence","breaths":4,"landOn":"exhale"}
 ]$json$, null, NULL),

('behavior.smallStep.en.v1', 1, 'en', 'behavior', 'One small step',
 array['avoidance'], array['behavior'], 3, 190, 310,
 array['reflection.notice.en.v1'], array['immediate_crisis'], null,
 $json$[
   {"type":"slot","name":"technique_bridge"},
   {"type":"fixed","text":"Bring to mind something you have been putting off. Not the whole task, only its first movement: opening the door, opening the file, or picking up the phone."},
   {"type":"silence","breaths":3},
   {"type":"fixed","text":"Imagine making only that first movement, and notice what happens in your body. You do not need to go any further."},
   {"type":"silence","breaths":4},
   {"type":"slot","name":"mid_bridge"},
   {"type":"fixed","text":"There is nothing you need to finish today. We only noticed what the first movement was like."},
   {"type":"silence","breaths":3,"landOn":"exhale"}
 ]$json$, null, NULL),

('closing.day.en.v1', 1, 'en', 'frame', 'Closing', array['ending'],
 array['relief','awareness','skill','behavior','closing'], 1, 55, 110,
 '{}', '{}', null,
 $json$[
   {"type":"fixed","text":"We are coming to the end. Let your breath move in its own way a few more times."},
   {"type":"silence","breaths":2,"landOn":"exhale"},
   {"type":"slot","name":"step_closing"},
   {"type":"silence","breaths":1,"landOn":"exhale"},
   {"type":"fixed","text":"When you open your eyes, take your time."}
 ]$json$, null, NULL)
on conflict (id) do nothing;

