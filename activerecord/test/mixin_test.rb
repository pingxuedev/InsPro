require 'abstract_unit'
require 'active_record/mixins/tree'
require 'active_record/mixins/list'
require 'active_record/mixins/touch'
require 'fixtures/mixin'

class TreeTest < Test::Unit::TestCase
  fixtures :mixins
  
  def test_has_child
    assert_equal true, @first.has_children?
    assert_equal false, @second.has_children?
    assert_equal false, @third.has_children?
  end

  def test_children
    assert_equal @first.children, [@second, @third]
    assert_equal @second.children, []
  end

  def test_parent
    assert_equal @second.parent, @first
    assert_equal @second.parent, @third.parent
    assert_nil @first.parent
  end
  
  def test_insert
    @extra = @first.children.create
    
    assert @extra
    
    assert_equal @extra.parent, @first
    assert_equal [@second, @third, @extra], @first.children
  end
  
  def test_delete
    assert_equal 3, Mixin.count
    @first.destroy
    assert_equal 0, Mixin.count
  end
end

class TouchTest < Test::Unit::TestCase
  fixtures :mixins
  
  def test_update
    assert_nil @first.updated_at
    @first.save
    assert_not_nil @first.updated_at
  end  

  def test_create
    @obj = Mixin.create({"parent" => @third})
    assert_not_nil @obj.updated_at
    assert_not_nil @obj.created_at
  end  
  
  
end


class ListTest < Test::Unit::TestCase
  fixtures :mixins
  
  def test_reordering
    
    assert_equal [ListMixin.find(2), ListMixin.find(3)], ListMixin.find_all("parent_id=1", "pos")
    
    ListMixin.find(2).move_lower
    
    assert_equal [ListMixin.find(3), ListMixin.find(2)], ListMixin.find_all("parent_id=1", "pos")
    
    ListMixin.find(2).move_higher

    assert_equal [ListMixin.find(2), ListMixin.find(3)], ListMixin.find_all("parent_id=1", "pos")
    
  end

  def test_insert
    new = ListMixin.create("parent_id"=>3)
    assert_equal 1, new.pos
    assert new.first?
    assert new.last?

    new = ListMixin.create("parent_id"=>3)
    assert_equal 2, new.pos
    assert !new.first?
    assert new.last?
    
    new = ListMixin.create("parent_id"=>3)
    assert_equal 3, new.pos    
    assert !new.first?
    assert new.last?
    
    new = ListMixin.create("parent_id"=>2)
    assert_equal 1, new.pos
    assert new.first?
    assert new.last?

  end  
end