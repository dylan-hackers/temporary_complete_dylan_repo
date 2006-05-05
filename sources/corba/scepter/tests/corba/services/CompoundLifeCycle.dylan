Module: scepter-tests
Author: Jason Trenouth
Copyright:    Original Code is Copyright (c) 1995-2004 Functional Objects, Inc.
              All rights reserved.
License:      Functional Objects Library Public License Version 1.0
Dual-license: GNU Lesser General Public License
Warranty:     Distributed WITHOUT WARRANTY OF ANY KIND

define test corba-services-idl-CompoundLifeCycle ()
  check("", test-idl-file, *corba-services-files*, "CompoundLifeCycle");
end test;

add-idl-file!(
  *corba-services-files*,
  "CompoundLifeCycle",
"// CosCompoundLifeCycle Module, p 6-30 CORBAservices,\n"
"// Life Cycle Service V1.0, 3/94\n"
"\n"
"#ifndef COSCOMPOUNDLIFECYCLE\n"
"#define COSCOMPOUNDLIFECYCLE\n"
"#include <LifeCycle.idl>\n"
"#include <Relationships.idl>\n"
"#include <Graphs.idl>\n"
"\n"
"module CosCompoundLifeCycle {\n"
"\tinterface OperationsFactory; \n"
"\tinterface Operations;\n"
"\tinterface Node;\n"
"\tinterface Role;\n"
"\tinterface Relationship;\n"
"\tinterface PropagationCriteriaFactory;\n"
"\n"
"\tenum Operation {copy, move, remove};\n"
"\n"
"\tstruct RelationshipHandle {\n"
"\t\t\tRelationship the_relationship;\n"
"\t\t\tCosObjectIdentity::ObjectIdentifier constant_random_id;\n"
"\t};\n"
"\n"
"\tinterface OperationsFactory {\n"
"\t\t\tOperations create_compound_operations();\n"
"\t};\n"
"\n"
"\tinterface Operations {\n"
"\t\t\tNode copy (\n"
"\t\t\t\t\t\tin Node starting_node,\n"
"\t\t\t\t\t\tin CosLifeCycle::FactoryFinder there,\n"
"\t\t\t\t\t\tin CosLifeCycle::Criteria the_criteria)\n"
"\t\t\t\traises (CosLifeCycle::NoFactory,\n"
"\t\t\t\t\t\tCosLifeCycle::NotCopyable,\n"
"\t\t\t\t\t\tCosLifeCycle::InvalidCriteria,\n"
"\t\t\t\t\t\tCosLifeCycle::CannotMeetCriteria);\n"
"\t\t\tvoid move (\n"
"\t\t\t\t\t\tin Node starting_node,\n"
"\t\t\t\t\t\tin CosLifeCycle::FactoryFinder there,\n"
"\t\t\t\t\t\tin CosLifeCycle::Criteria the_criteria)\n"
"\t\t\t\traises (CosLifeCycle::NoFactory,\n"
"\t\t\t\t\t\tCosLifeCycle::NotMovable,\n"
"\t\t\t\t\t\tCosLifeCycle::InvalidCriteria,\n"
"\t\t\t\t\t\tCosLifeCycle::CannotMeetCriteria);\n"
"\t\t\tvoid remove (in Node starting_node)\n"
"\t\t\t\traises (CosLifeCycle::NotRemovable);\n"
"\t\t\tvoid destroy();\n"
"\t\t};\n"
"\n"
"\tinterface Node : CosGraphs::Node {\n"
"\t\t\texception NotLifeCycleObject {};\n"
"\t\t\tvoid copy_node ( in CosLifeCycle::FactoryFinder there,\n"
"\t\t\t\t\t\tin CosLifeCycle::Criteria the_criteria,\n"
"\t\t\t\t\t\tout Node new_node,\n"
"\t\t\t\t\t\tout Roles roles_of_new_node)\n"
"\t\t\t\traises (CosLifeCycle::NoFactory,\n"
"\t\t\t\t\t\tCosLifeCycle::NotCopyable,\n"
"\t\t\t\t\t\tCosLifeCycle::InvalidCriteria,\n"
"\t\t\t\t\t\tCosLifeCycle::CannotMeetCriteria);\n"
"\t\t\tvoid move_node (in CosLifeCycle::FactoryFinder there, \n"
"\t\t\t\t\t\tin CosLifeCycle::Criteria the_criteria)\n"
"\t\t\t\traises (CosLifeCycle::NoFactory,\n"
"\t\t\t\t\t\tCosLifeCycle::NotMovable,\n"
"\t\t\t\t\t\tCosLifeCycle::InvalidCriteria,\n"
"\t\t\t\t\t\tCosLifeCycle::CannotMeetCriteria);\n"
"\t\t\tvoid remove_node ()\n"
"\t\t\t\traises (CosLifeCycle::NotRemovable);\n"
"\t\t\tCosLifeCycle::LifeCycleObject get_life_cycle_object()\n"
"\t\t\t\traises (NotLifeCycleObject);\n"
"\t\t};\n"
"\n"
"\tinterface Role : CosGraphs::Role {\n"
"\t\t\tRole copy_role (in CosLifeCycle::FactoryFinder there, \n"
"\t\t\t\t\t\tin CosLifeCycle::Criteria the_criteria)\n"
"\t\t\t\traises (CosLifeCycle::NoFactory,\n"
"\t\t\t\t\t\tCosLifeCycle::NotCopyable,\n"
"\t\t\t\t\t\tCosLifeCycle::InvalidCriteria,\n"
"\t\t\t\t\t\tCosLifeCycle::CannotMeetCriteria);\n"
"\t\t\tvoid move_role (in CosLifeCycle::FactoryFinder there, \n"
"\t\t\t\t\t\tin CosLifeCycle::Criteria the_criteria)\n"
"\t\t\t\traises (CosLifeCycle::NoFactory,\n"
"\t\t\t\t\t\tCosLifeCycle::NotMovable,\n"
"\t\t\t\t\t\tCosLifeCycle::InvalidCriteria,\n"
"\t\t\t\t\t\tCosLifeCycle::CannotMeetCriteria);\n"
"\t\t\tCosGraphs::PropagationValue life_cycle_propagation (\n"
"\t\t\t\t\t\tin Operation op,\n"
"\t\t\t\t\t\tin RelationshipHandle rel,\n"
"\t\t\t\t\t\tin CosRelationships::RoleName to_role_name,\n"
"\t\t\t\t\t\tout boolean same_for_all);\n"
"\t\t};\n"
"\n"
"\tinterface Relationship : \n"
"\t\t\t\tCosRelationships::Relationship {\n"
"\t\t\tRelationship copy_relationship (\n"
"\t\t\t\t\t\tin CosLifeCycle::FactoryFinder there,\n"
"\t\t\t\t\t\tin CosLifeCycle::Criteria the_criteria,\n"
"\t\t\t\t\t\tin CosGraphs::NamedRoles new_roles)\n"
"\t\t\t\traises (CosLifeCycle::NoFactory,\n"
"\t\t\t\t\t\tCosLifeCycle::NotCopyable,\n"
"\t\t\t\t\t\tCosLifeCycle::InvalidCriteria,\n"
"\t\t\t\t\t\tCosLifeCycle::CannotMeetCriteria);\n"
"\t\t\tvoid move_relationship (\n"
"\t\t\t\t\t\tin CosLifeCycle::FactoryFinder there,\n"
"\t\t\t\t\t\tin CosLifeCycle::Criteria the_criteria)\n"
"\t\t\t\traises (CosLifeCycle::NoFactory,\n"
"\t\t\t\t\t\tCosLifeCycle::NotMovable,\n"
"\t\t\t\t\t\tCosLifeCycle::InvalidCriteria,\n"
"\t\t\t\t\t\tCosLifeCycle::CannotMeetCriteria);\n"
"\t\t\tCosGraphs::PropagationValue life_cycle_propagation (\n"
"\t\t\t\t\t\tin Operation op,\n"
"\t\t\t\t\t\tin CosRelationships::RoleName from_role_name,\n"
"\t\t\t\t\t\tin CosRelationships::RoleName to_role_name,\n"
"\t\t\t\t\t\tout boolean same_for_all);\n"
"\t};\n"
"\n"
"\tinterface PropagationCriteriaFactory {\n"
"\t\t\tCosGraphs::TraversalCriteria create(in Operation op);\n"
"\t};\n"
"\n"
"};\n"
"#endif\n"
"\n");