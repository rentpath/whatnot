require 'spec_helper'

module Whatnot
  describe DimacsCNFVar do
    let(:test_table) do
      {:name=>:Y5A3T3,
       :domain=>
        [{:kid_ids=>[2, 10, 11],
          :subject_ids=>[4, 3, 2, 1],
          :grade_id=>1,
          :hosting_slot=>:A1H1,
          :class_id=>1,
          :day=>5},
         {:kid_ids=>[2, 10, 11],
          :subject_ids=>[4, 3, 2, 1],
          :grade_id=>1,
          :hosting_slot=>:A2H1,
          :class_id=>4,
          :day=>5},
         {:kid_ids=>[2, 10, 11],
          :subject_ids=>[4, 3, 2, 1],
          :grade_id=>1,
          :hosting_slot=>:A2H2,
          :class_id=>7,
          :day=>5},
         {:null_class=>1},
         {:null_class=>2},
         {:null_class=>3},
         {:null_class=>4}],
       :argument_set=>
        [[{:kid_ids=>[2, 10, 11],
           :subject_ids=>[4, 3, 2, 1],
           :grade_id=>1,
           :hosting_slot=>"A1H1",
           :class_id=>1,
           :day=>5},
          579],
         [{:kid_ids=>[2, 10, 11],
           :subject_ids=>[4, 3, 2, 1],
           :grade_id=>1,
           :hosting_slot=>"A2H1",
           :class_id=>4,
           :day=>5},
          580],
         [{:kid_ids=>[2, 10, 11],
           :subject_ids=>[4, 3, 2, 1],
           :grade_id=>1,
           :hosting_slot=>"A2H2",
           :class_id=>7,
           :day=>5},
          581],
         [{:null_class=>1}, 582],
         [{:null_class=>2}, 583],
         [{:null_class=>3}, 584],
         [{:null_class=>4}, 585]]}
    end

    describe '#argument_set' do
      it 'works' do
        var = DimacsCNFVar.new(test_table[:name], test_table[:domain], key_iter: 579)
        expect(var.argument_set).to eq(test_table[:argument_set])
      end
    end
  end
end
