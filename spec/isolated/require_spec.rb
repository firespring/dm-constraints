shared_examples "require 'dm-constraints'" do
  it 'extends Model descendants with the constraint API' do
    expect(DataMapper::Model.descendants).not_to be_empty
    DataMapper::Model.descendants.all? do |model|
      expect(model.respond_to?(:auto_migrate_constraints_down, true)).to be(true)
      expect(model.respond_to?(:auto_migrate_constraints_up,   true)).to be(true)
    end
  end

  it 'includes the constraint API into the adapter' do
    expect(@adapter.respond_to?(:constraint_exists?             )).to be(true)
    expect(@adapter.respond_to?(:create_relationship_constraint )).to be(true)
    expect(@adapter.respond_to?(:destroy_relationship_constraint)).to be(true)
  end
end
