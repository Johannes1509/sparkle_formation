require_relative "../../spec"

describe SparkleFormation::SparkleAttribute::Azure do
  before do
    klass = Class.new(AttributeStruct)
    klass.include(SparkleFormation::SparkleAttribute)
    klass.include(SparkleFormation::SparkleAttribute::Azure)
    klass.include(SparkleFormation::Utils::TypeCheckers)
    @attr = klass.new
    @attr._camel_keys = true
    @attr._camel_style = :no_leading
    @sfn = SparkleFormation.new(:test, :provider => :azure)
  end

  describe "depends_on helper method" do
    it "should generate a depends on array" do
      _(@attr.depends_on!("type1/name_1", "type2/name_2")).must_equal([
        "type1/name_1", "type2/name_2",
      ])
      _(@attr._dump).must_equal(
        "dependsOn" => [
          "type1/name_1",
          "type2/name_2",
        ],
      )
    end

    it "should generate depends on array using defined resources" do
      @sfn.overrides do
        dynamic!(:network_security_groups, :test)
        resources.my_resource.depends_on!(
          :test_network_security_groups
        )
      end
      result = @sfn.dump
      _(result["resources"].last["dependsOn"]).must_equal(
        ["Microsoft.Network/networkSecurityGroups/testNetworkSecurityGroups"]
      )
    end

    it "should raise an error when resource name lookup fails" do
      @sfn.overrides do
        dynamic!(:network_security_groups, :test)
        resources.my_resource.depends_on!(
          :unknown_network_security_groups
        )
      end
      _{ @sfn.dump }.must_raise SparkleFormation::Error::NotFound::Resource
    end
  end

  describe "resource_id helper method" do
    it "should generate a direct resource id" do
      _(@attr.resource_id!("fubar_type", "fubar").dump).must_equal "[resourceId('fubar_type/fubar')]"
    end

    it "should generate a resource id using defined resources" do
      @sfn.overrides do
        dynamic!(:network_security_groups, :test)
        resources.my_resource.that_resource resource_id!(
          :test_network_security_groups
        )
      end
      result = @sfn.dump
      _(result["resources"].last["thatResource"]).must_equal(
        "[resourceId('Microsoft.Network/networkSecurityGroups', 'testNetworkSecurityGroups')]"
      )
    end

    it "should raise an error when resource name lookup fails" do
      @sfn.overrides do
        dynamic!(:network_security_groups, :test)
        resources.my_resource.that_resource resource_id!(
          :unknown_network_security_groups
        )
      end
      _{ @sfn.dump }.must_raise SparkleFormation::Error::NotFound::Resource
    end
  end

  describe "stack_output helper method" do
    it "should generate stack output reference" do
      _(@attr.stack_output!(:stack_name, :output_name)._dump).must_equal(
        "[reference('stackName').outputs.outputName.value]"
      )
    end

    it "should accept no hump flagging" do
      _(@attr.stack_output!("stack_name"._no_hump, "output_name")._dump).must_equal(
        "[reference('stack_name').outputs.outputName.value]"
      )
    end
  end

  describe "structure dump behavior" do
    it "should convert resources Hash type to Array type" do
      @attr.resources.my_resource.type "testing"
      result = @attr._dump
      _(result["resources"]).must_be_kind_of Array
      _(result["resources"].first["name"]).must_equal "myResource"
      _(result["resources"].first["type"]).must_equal "testing"
    end
  end

  describe "intrinsic functions" do
    it "should generate add function" do
      _(@attr.add!(1, 2)._dump).must_equal "[add(1, 2)]"
    end

    it "should generate copyIndex function" do
      _(@attr.copy_index!(1)._dump).must_equal "[copyIndex(1)]"
    end

    it "should generate div function" do
      _(@attr.div!(1, 2)._dump).must_equal "[div(1, 2)]"
    end

    it "should generate int function" do
      _(@attr.int!("2")._dump).must_equal "[int('2')]"
    end

    it "should generate length function" do
      _(@attr.length!("string")._dump).must_equal "[length('string')]"
    end

    it "should generate mod function" do
      _(@attr.mod!(1, 2)._dump).must_equal "[mod(1, 2)]"
    end

    it "should generate mul function" do
      _(@attr.mul!(1, 2)._dump).must_equal "[mul(1, 2)]"
    end

    it "should generate sub function" do
      _(@attr.sub!(1, 2)._dump).must_equal "[sub(1, 2)]"
    end

    it "should generate base64 function" do
      _(@attr.base64!("string")._dump).must_equal "[base64('string')]"
    end

    it "should generate concat function" do
      _(@attr.concat!("string1", "string2")._dump).must_equal "[concat('string1', 'string2')]"
    end

    it "should generate padLeft function" do
      _(@attr.pad_left!("string", 10, "a")._dump).must_equal(
        "[padLeft('string', 10, 'a')]"
      )
    end

    it "should generate replace function" do
      _(@attr.replace!("string", "other")._dump).must_equal "[replace('string', 'other')]"
    end

    it "should generate split function" do
      _(@attr.split!("string", "delim")._dump).must_equal "[split('string', 'delim')]"
    end

    it "should generate string function" do
      _(@attr.string!(1)._dump).must_equal "[string(1)]"
    end

    it "should generate substring function" do
      _(@attr.substring!("string", 1, 2)._dump).must_equal "[substring('string', 1, 2)]"
    end

    it "should generate toLower function" do
      _(@attr.to_lower!("string")._dump).must_equal "[toLower('string')]"
    end

    it "should generate toUpper function" do
      _(@attr.to_upper!("string")._dump).must_equal "[toUpper('string')]"
    end

    it "should generate trim function" do
      _(@attr.trim!("string")._dump).must_equal "[trim('string')]"
    end

    it "should generate uniqueString function" do
      _(@attr.unique_string!("string", "otherstring")._dump).must_equal "[uniqueString('string', 'otherstring')]"
    end

    it "should generate uri function" do
      _(@attr.uri!("http://localhost", "home")._dump).must_equal "[uri('http://localhost', 'home')]"
    end

    it "should generate deployment function" do
      _(@attr.deployment!._dump).must_equal "[deployment()]"
    end

    it "should generate parameters function" do
      _(@attr.parameters!(:name)._dump).must_equal "[parameters('name')]"
    end

    it "should generate formatted name parameters function" do
      _(@attr.parameters!(:some_name)._dump).must_equal "[parameters('someName')]"
    end

    it "should generate variables function" do
      _(@attr.variables!(:name)._dump).must_equal "[variables('name')]"
    end

    it "should generate listKeys function" do
      _(@attr.list_keys!("location")._dump).must_equal "[listKeys('location')]"
    end

    it "should generate providers function" do
      _(@attr.providers!("namespace")._dump).must_equal "[providers('namespace')]"
    end

    it "should generate reference function" do
      _(@attr.reference!("thing")._dump).must_equal "[reference('thing')]"
    end

    it "should generate resourceGroup function" do
      _(@attr.resource_group!._dump).must_equal "[resourceGroup()]"
    end

    it "should generate resourceId function" do
      _(@attr.resource_id!("group", "type", "name")._dump).must_equal "[resourceId('group', 'type', 'name')]"
    end

    it "should generate a subscription function" do
      _(@attr.subscription!._dump).must_equal "[subscription()]"
    end
  end

  describe "Complex intrinsic function usage" do
    it "should allow nesting helper method functions" do
      @sfn.overrides do
        value add!(parameters!(:one), parameters!(:two))
      end
      _(@sfn.dump).must_equal "value" => "[add(parameters('one'), parameters('two'))]"
    end

    it "should allow method chaining" do
      @sfn.overrides do
        value deployment!.properties.index(1)
      end
      _(@sfn.dump).must_equal "value" => "[deployment().properties.index(1)]"
    end

    it "should allow complex method chaining" do
      @sfn.overrides do
        value add!(
          int!(parameters!(:first_value)),
          int!(providers!("namespace", "type").apiVersion[0])
        )
      end
      _(@sfn.dump).must_equal "value" => "[add(int(parameters('firstValue')), int(providers('namespace', 'type').apiVersion[0]))]"
    end
  end

  describe "Setting intrinsic function values" do
    it "should set the root function structure" do
      @sfn.overrides do
        value deployment!.first.second.third.fourth
      end
      _(@sfn.dump).must_equal "value" => "[deployment().first.second.third.fourth]"
    end

    it "should set the root function structure in arrays" do
      @sfn.overrides do
        value [
          :one,
          :two,
          deployment!.first.second.third,
        ]
      end
      _(@sfn.dump).must_equal "value" => ["one", "two", "[deployment().first.second.third]"]
    end

    it "should set the root function structure in hashes" do
      @sfn.overrides do
        value(
          :thing => deployment!.first.second.third,
        )
      end
      _(@sfn.dump).must_equal(
        "value" => {
          "thing" => "[deployment().first.second.third]",
        },
      )
    end

    it "should set the root function structure in nested array hashes" do
      @sfn.overrides do
        value [
          :thing1,
          {:thing2 => deployment!.first.second.third},
        ]
      end
      _(@sfn.dump).must_equal(
        "value" => [
          "thing1",
          {"thing2" => "[deployment().first.second.third]"},
        ],
      )
    end

    it "should set the root function structure in nested hash arrays" do
      @sfn.overrides do
        value(
          :thing1 => [
            :thing1,
            {:thing2 => deployment!.first.second.third},
          ],
        )
      end
      _(@sfn.dump).must_equal(
        "value" => {
          "thing1" => [
            "thing1",
            {"thing2" => "[deployment().first.second.third]"},
          ],
        },
      )
    end
  end
end
