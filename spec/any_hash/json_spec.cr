require "../spec_helper"

describe AnyHash::JSON do
  context ".deep_cast_value" do
    valid_values = {nil, 1, 2_i64, 13.37, true, :foo, "bar", Time.now}

    it "raises TypeCastError when passed invalid type" do
      expect_raises TypeCastError, /cast from Slice\(UInt8\) to .*? failed/ do
        AnyHash::JSON.deep_cast_value Bytes.empty.as(Bytes | Int64)
      end
      expect_raises TypeCastError, /cast from Char to .*? failed/ do
        AnyHash::JSON.deep_cast_value 'a'.as(Char | String)
      end
    end

    it "accepts valid JSON type" do
      valid_values.each do |v|
        AnyHash::JSON.deep_cast_value(v).should eq(v)
      end
    end

    it "converts Tuple to an Array" do
      AnyHash::JSON.deep_cast_value({1, 2, 3}).should eq([1, 2, 3])
    end

    it "converts Tuple to an Array (recursive)" do
      AnyHash::JSON.deep_cast_value({ { {1, 2, 3} } }).should eq([[[1, 2, 3]]])
    end

    it "converts NamedTuple to a Hash" do
      AnyHash::JSON.deep_cast_value({foo: true, bar: 1337})
                   .should eq({:foo => true, :bar => 1337})
    end

    it "converts NamedTuple to a Hash (recursive)" do
      AnyHash::JSON.deep_cast_value({foo: {jazz: true, swing: :always}, bar: 1337})
                   .should eq({:foo => {:jazz => true, :swing => :always}, :bar => 1337})
    end

    it "accepts valid JSON type (recursive)" do
      recursive_values = {
        [[[valid_values.to_a]]],
        { { {valid_values} } },
        [{[valid_values]}],
        tuple = {named: :tuple, powers: {types: true}},
        {:good => "hash", :bad => tuple},
      }
      recursive_values.each do |v|
        AnyHash::JSON.deep_cast_value(v).should be_truthy
      end
    end
  end

  context ".deep_merge!" do
    it "merges given Hash with another AnyHash::JSON, Hash or NamedTuple" do
      hash = {} of AnyHash::JSONTypes::Key => AnyHash::JSONTypes::Value

      AnyHash::JSON.deep_merge!(hash, *{
        AnyHash::JSON.new({foo: {bar: true}}),
        {:foo => {swing: 133.7}},
        {foo: {jazz: "60s"}},
        {foo: {roar: {} of Symbol => Symbol}},
        {:foo => {roar: {"alfa" => "beta"}}},
      }).should eq(hash)

      hash.should eq({
        :foo => {:bar => true, :swing => 133.7, :jazz => "60s", :roar => {"alfa" => "beta"}},
      })
    end
  end

  context "#initialize" do
    it "raises TypeCastError when passed invalid type" do
      expect_raises TypeCastError, /cast from Slice\(UInt8\) to .*? failed/ do
        AnyHash::JSON.new({invalid: Bytes.empty.as(Bytes | Int64)})
      end
      expect_raises TypeCastError, /cast from Char to .*? failed/ do
        AnyHash::JSON.new({why_oh_why_i_did_not_call_to_s: 'a'.as(Char | String)})
      end
    end

    it "takes another AnyHash::JSON, Hash or NamedTuple as an initial value" do
      AnyHash::JSON.new(AnyHash::JSON.new({foo: {bar: true}}))
                   .to_h.should eq({:foo => {:bar => true}})
      AnyHash::JSON.new({foo: {bar: true}})
                   .to_h.should eq({:foo => {:bar => true}})
      AnyHash::JSON.new({:foo => {:bar => true}})
                   .to_h.should eq({:foo => {:bar => true}})
    end
  end

  context "#==" do
    samples = {
      eq:  {AnyHash::JSON.new({foo: 1337}), {foo: 1337_i64}, {:foo => 1337}},
      neq: {AnyHash::JSON.new({json: :jmom}), {foo: false}, {"bar" => "fly"}},
    }

    it "compares keys and values of AnyHash::JSON, Hash or NamedTuple" do
      samples[:eq].in_groups_of(2, samples[:eq].last).each do |(hash1, hash2)|
        (hash1 == hash2).should be_true
      end
      samples[:neq].in_groups_of(2, samples[:neq].first).each do |(hash1, hash2)|
        (hash1 != hash2).should be_true
      end
    end
  end
end
