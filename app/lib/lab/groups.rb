# The groups /lab/agree tabulates by, and how a participant's profile maps onto them.
#
# Gender and generation come from the profile metamaps (3 and 5, the same nodes as
# GENDER_CHOICES / AGE_CHOICES). "Simply-Human" is the profile's opt-out, so it is
# counted overall but forms no group. Region is the continent of the profile country.
module Lab
  module Groups
    GENDER_METAMAP = 3
    GENERATION_METAMAP = 5

    DIMENSIONS = {
      gender: {
        column: :gender_id, label: 'Gender',
        groups: { 207 => 'Men', 208 => 'Women' }
      },
      generation: {
        column: :generation_id, label: 'Generation',
        groups: { 405 => 'Youth', 406 => 'Experience', 407 => 'Wisdom' }
      },
      region: {
        column: :region, label: 'Region',
        groups: { 'AF' => 'Africa', 'AS' => 'Asia', 'EU' => 'Europe', 'NA' => 'North America',
                  'SA' => 'South America', 'OC' => 'Oceania' }
      }
    }.freeze

    # Frozen copy of the parts of a profile we tabulate by.
    def self.snapshot(participant)
      return {} unless participant
      nodes = MetamapNodeParticipant.where(participant_id: participant.id,
                                           metamap_id: [GENDER_METAMAP, GENERATION_METAMAP])
                                    .pluck(:metamap_id, :metamap_node_id).to_h
      country = participant.country_code.to_s.upcase.presence
      {
        gender_id: nodes[GENDER_METAMAP],
        generation_id: nodes[GENERATION_METAMAP],
        country_code: country,
        region: country && Geocountry.where(iso: country).pick(:continent)
      }
    end

    # [[dimension_key, group_label], ...] for the groups this snapshot belongs to
    def self.memberships(snap)
      DIMENSIONS.filter_map do |key, dim|
        label = dim[:groups][snap[dim[:column]]]
        [key, label] if label
      end
    end
  end
end
