RSpec::Matchers.define :allow_op_on_object do |op, object, *args|
  match do |access|
    access.can?("#{op}_with_token".to_sym, object) && access.can?(op, object, *args)
  end

  failure_message do
    "Expected to be able to perform operation #{op} on object #{object}"
  end
end
