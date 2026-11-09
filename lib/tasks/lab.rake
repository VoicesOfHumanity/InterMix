# Tasks for the /lab/agree experiment.
#
#   rake lab:questions          create the starter questions (idempotent)
#   rake lab:demo_seed          add simulated answers + votes so the pages show what
#                               it looks like with activity (staging only!)
#   rake lab:demo_clear         remove everything lab:demo_seed added
#   rake lab:synthesize[ID]     ask the AI for a common-ground draft for question ID
#
# Demo data is always marked: answers have author_kind 'demo' (shown with a "demo"
# badge), votes have demo = true and NEGATIVE participant ids, so no real account is
# touched and the cleanup is exact.
namespace :lab do
  LAB_QUESTIONS = [
    { title: 'What should every child in the world have a right to?',
      intro: 'Not what would be nice - what every child, everywhere, should be able to count on.' },
    { title: 'What should AI never be allowed to decide on its own?',
      intro: 'Machines are being handed more decisions every year. Where should a human always have the final say?' },
    { title: 'What makes a life well lived?',
      intro: 'Looking back at the end, what would make you say it was a good one?' }
  ].freeze

  # base: how broadly appealing; then per-group adjustments. Invented for the demo -
  # some answers are meant to bridge, some to split groups, so the results page has
  # something to show.
  LAB_DEMO_ANSWERS = {
    0 => [
      ['Clean water, enough food, and a safe place to sleep.', 0.80, {}],
      ['To grow up without being forced to work or to fight in wars.', 0.70, {}],
      ['Free schooling, at least until they can read, write and do sums.', 0.65, { 'Asia' => 0.1 }],
      ['Protection from violence, including at home.', 0.60, { 'Women' => 0.25, 'Men' => -0.05 }],
      ['Time to play and just be a child.', 0.55, { 'Women' => 0.15, 'Wisdom' => 0.1 }],
      ['Free healthcare and vaccinations.', 0.55, { 'North America' => -0.2, 'Europe' => 0.2 }],
      ['A name, a birth certificate and a nationality.', 0.45, { 'Africa' => 0.2 }],
      ['To be listened to and have a say in decisions about their own life.', 0.40, { 'Youth' => 0.4, 'Wisdom' => -0.3 }],
      ['A mother and a father who are married and raise them together.', 0.35, { 'Wisdom' => 0.35, 'Youth' => -0.35, 'Africa' => 0.15 }],
      ['Time in nature, and to learn how the natural world works.', 0.35, { 'Experience' => 0.1 }],
      ['To be raised in their family\'s faith.', 0.25, { 'Africa' => 0.4, 'Asia' => 0.15, 'Europe' => -0.3 }],
      ['Access to the internet.', 0.20, { 'Youth' => 0.3, 'Wisdom' => -0.15 }]
    ],
    1 => [
      ['Whether to use deadly force against a person.', 0.75, {}],
      ['Whether to launch nuclear weapons. Ever.', 0.70, { 'Wisdom' => 0.1 }],
      ['Whether someone goes to prison.', 0.60, {}],
      ['Who gets medical treatment when there is not enough to go round.', 0.55, { 'Wisdom' => 0.2 }],
      ['Anything about my life without telling me an AI was involved.', 0.55, { 'Europe' => 0.2 }],
      ['Nothing at all - AI should advise, and a person should always decide.', 0.50, { 'Wisdom' => 0.3, 'Youth' => -0.3 }],
      ['Who can vote, or how votes are counted.', 0.45, {}],
      ['Who gets hired, promoted or fired.', 0.40, { 'Youth' => 0.2 }],
      ['What children are taught in school.', 0.35, { 'North America' => 0.2, 'Asia' => -0.1 }],
      ['Whether a loan or mortgage is approved.', 0.30, { 'Youth' => 0.15 }]
    ],
    2 => [
      ['Having people you love, who love you back.', 0.80, {}],
      ['Leaving the world a little better than you found it.', 0.60, {}],
      ['Work that means something to you.', 0.50, { 'Experience' => 0.2 }],
      ['Enough money that you are not worried every month.', 0.50, { 'Youth' => 0.15, 'Africa' => 0.2, 'South America' => 0.15 }],
      ['Good health, for as long as possible.', 0.50, { 'Wisdom' => 0.3, 'Youth' => -0.2 }],
      ['The freedom to choose your own path.', 0.50, { 'Youth' => 0.25, 'North America' => 0.15 }],
      ['Being useful to your community.', 0.45, { 'Asia' => 0.2, 'Wisdom' => 0.15 }],
      ['Time in nature, and time to rest.', 0.35, { 'Europe' => 0.15, 'Oceania' => 0.15 }],
      ['Faith in God, and living by it.', 0.30, { 'Africa' => 0.4, 'South America' => 0.2, 'Europe' => -0.3 }],
      ['Adventure, travel and new experiences.', 0.30, { 'Youth' => 0.35, 'Wisdom' => -0.3 }]
    ]
  }.freeze

  def lab_pick_weighted(items, weights, rng)
    r = rng.rand * weights.sum
    items.each_with_index { |it, i| return it if (r -= weights[i]) <= 0 }
    items.last
  end

  def lab_demo_population(rng)
    weighted = ->(h) { lab_pick_weighted(h.keys, h.values, rng) }
    {
      gender_id: weighted.call({ 207 => 45, 208 => 45, nil => 10 }),
      generation_id: weighted.call({ 405 => 30, 406 => 40, 407 => 25, nil => 5 }),
      region: weighted.call({ 'EU' => 28, 'NA' => 24, 'AS' => 16, 'AF' => 14, 'SA' => 10, 'OC' => 8 })
    }
  end

  desc 'Create the starter /lab/agree questions (idempotent)'
  task questions: :environment do
    LAB_QUESTIONS.each_with_index do |q, i|
      rec = LabQuestion.find_or_initialize_by(title: q[:title])
      rec.update!(intro: q[:intro], position: i, active: true)
      puts "question #{rec.id}: #{rec.title}"
    end
  end

  desc 'Seed simulated answers and votes for the /lab/agree demo (staging)'
  task demo_seed: :questions do
    rng = Random.new(42)
    labels = Lab::Groups::DIMENSIONS.to_h { |_, d| [d[:column], d[:groups]] }
    voter_id = -(LabVote.where('participant_id < 0').minimum(:participant_id).to_i.abs + 1)

    LAB_QUESTIONS.each_with_index do |q, qi|
      question = LabQuestion.find_by!(title: q[:title])
      if question.lab_answers.where(author_kind: 'demo').exists?
        puts "#{question.id}: already has demo data, skipping (run lab:demo_clear first to redo)"
        next
      end
      answers = LAB_DEMO_ANSWERS[qi].map do |body, base, mods|
        snap = lab_demo_population(rng)
        a = question.lab_answers.create!(body: body, author_kind: 'demo', **snap)
        [a, base, mods]
      end

      rows = []
      170.times do
        voter = lab_demo_population(rng)
        groups = labels.filter_map { |col, map| map[voter[col]] }
        created = Time.now - rng.rand(14 * 86_400)
        rng.rand(1..4).times do
          token = SecureRandom.hex(12)
          shown = answers.sample(Lab::Picker::ROUND_SIZE, random: rng)
          weights = shown.map do |_, base, mods|
            appeal = base + groups.sum { |g| mods[g].to_f }
            Math.exp(3.5 * appeal)
          end
          picked = []
          pool, w = shown.dup, weights.dup
          2.times do
            choice = lab_pick_weighted(pool, w, rng)
            picked << choice
            idx = pool.index(choice)
            pool.delete_at(idx)
            w.delete_at(idx)
          end
          shown.each do |a, _, _|
            rows << { lab_question_id: question.id, lab_answer_id: a.id, participant_id: voter_id,
                      round_token: token, picked: picked.any? { |p, _, _| p.id == a.id }, demo: true,
                      gender_id: voter[:gender_id], generation_id: voter[:generation_id],
                      region: voter[:region], country_code: nil, created_at: created }
          end
        end
        voter_id -= 1
      end
      LabVote.insert_all(rows)
      question.update_columns(answers_at_last_synth: question.human_answer_count)
      puts "#{question.id}: #{answers.size} demo answers, #{rows.size / Lab::Picker::ROUND_SIZE} demo rounds"
    end
  end

  desc 'Remove all /lab/agree demo data'
  task demo_clear: :environment do
    votes = LabVote.where(demo: true).delete_all
    ids = LabAnswer.where(author_kind: 'demo').pluck(:id)
    votes += LabVote.where(lab_answer_id: ids).delete_all
    answers = LabAnswer.where(id: ids).delete_all
    puts "removed #{answers} demo answers and #{votes} demo votes"
  end

  desc 'Ask the AI for a common-ground draft: rake lab:synthesize[QUESTION_ID]'
  task :synthesize, [:id] => :environment do |_, args|
    abort 'No AI key configured (credentials anthropic.api_key or ANTHROPIC_API_KEY)' unless Lab::Ai.enabled?
    question = LabQuestion.find(args[:id])
    answer = Lab::Ai.draft_common_ground(question)
    puts answer ? "drafted ##{answer.id}: #{answer.body}\n  note: #{answer.ai_note}" : 'no draft produced (see log)'
  end
end
