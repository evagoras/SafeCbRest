component
{


	property name="wirebox" inject="wirebox";
	property name="nullValueReplacementToken" inject="coldbox:setting:nullValueReplacementToken";
	property name="xmlConverter" inject="xmlConverter@coldbox";


	// Global variables that are separate from properties
	variables.categorizedProperties = {};
	variables.errors = {};
	variables.populatedProperties = [];
	variables.namedSimpleProperties = {};


	public any function init()
	{
		// introspects and stores the properties of the Bean in categories
		variables.categorizedProperties = returnCategorizedProperties();
		variables.namedSimpleProperties = returnNamedSimpleProperties();
		return this;
	}


	/**
	 * @hint Returns the query params of either the populated or a specified list of properties.
	 * @properties The properties to return the queryparams for. Defaults to all populated.
	 * @cfsqltypes Name-Value pairs of types to use. If not passed, defaults will be used.
	 */
	public struct function returnQueryParams
	(
		array properties = variables.populatedProperties,
		struct cfsqltypes = {}
	)
	{
		// output
		var params = {};
		var data = this.serialize();
		for ( var dataKey in data )
		{
			if ( ! data.keyExists( dataKey ) )
				data[ dataKey ] = nullValueReplacementToken
			;
		}
		// flag for NULL columns
		var isColumnValueNull = false;
		// the value of the column to set
		var columnValue = "";
		for ( var propertyKey in arguments.properties )
		{
			// reset all vars for each loop iteration
			isColumnValueNull = false;
			columnValue = "";
			if ( data[ propertyKey ] == nullValueReplacementToken )
			{
				columnValue = "";
				isColumnValueNull = true;
			}
			else
			{
				// remove the chr(2) left padding added in the serialization
				columnValue = removeBeginningChar2( data[ propertyKey ] );
				isColumnValueNull = false;
			}
			params[ propertyKey ] = {
				value = columnValue,
				cfsqltype = arguments.cfsqltypes.keyExists( propertyKey )
					? arguments.cfsqltypes[ propertyKey ]
					: returnPropertyCfsqltype( propertyKey ),
				null = isColumnValueNull
			};
		}
		return params;
	}


	public string function serializeAs
	(
		required string format
	)
	{
		var out = "";
		switch ( arguments.format )
		{
			case "xml":
				out = xmlConverter.toXml
				(
					data = this.serialize(),
					rootName = "data"
				);
				out = removeChar2( out );
			break;
			case "json":
				out = serializeAsJson();
			break;
			default:
				out = serializeAsJson();
			break;
		}
		return out;
	}


	/**
	 * @hint Returns a boolean flag if there are no errors after population
	 */
	public boolean function validates()
	{
		if ( variables.errors.count() == 0 )
			validate()
		;
		return variables.errors.count() ? false : true;
	}


	/**
	 * @hint An indicator of whether the Bean has validation errors
	 */
	public boolean function hasErrors()
	{
		return variables.errors.count();
	}


	/**
	 * @hint Returns the validation errors of the populated Bean
	 */
	public struct function returnErrors()
	{
		return variables.errors;
	}


	/**
	 * @hint Validates the populated Bean using the cbValidate module
	 * @context Used for recursive validations to know the calling Bean
	 */
	public struct function validate
	( string context = "" )
	{
		var errors = validateSimpleProperties( context = arguments.context );
		var directPropertiesErrors = validateDirectProperties( contect = arguments.context );
		errors.append( directPropertiesErrors );
		var oneToOnePropertiesErrors = validateOneToOneProperties( context = arguments.context );
		errors.append( oneToOnePropertiesErrors );
		var oneToManyPropertiesErrors = validateOneToManyProperties( context = arguments.context );
		errors.append( oneToManyPropertiesErrors );
		// remove multiple errors from a key if one of them is a REQUIRED error
		errors = reduceRequiredErrors( errors );
		// assign the errors to a global errors variable
		variables.errors = errors;
		return errors;
	}


	/**
	 * @hint Can populate from a QUERY, a STRUCT or a JSON string
	 * @memento The data to populate with
	 */
	public void function populate
	( required any memento )
	{
		var data = {};
		// Convert input into a CF STRUCT depending on the argument type
		if ( isJson( arguments.memento ) )
			data = deserializeJson( arguments.memento )
		;
		if ( isQuery( arguments.memento ) )
			data = queryToStruct( arguments.memento )
		;
		if ( isStruct( arguments.memento ) )
			data = arguments.memento
		;
		// populate all the properties in this Bean
		populateSimpleProperties( memento = data );
		populateDirectProperties( memento = data );
		populateOneToOneProperties( memento = data );
		populateOneToManyProperties( memento = data );
	}


	/**
	 * @hint Returns the Populated Bean as a STRUCT
	 */
	public struct function serialize
	( boolean enforceStrings = true )
	{
		var s = serializeSimpleProperties( enforceStrings = arguments.enforceStrings );
		s.append( serializeDirectProperties( enforceStrings = arguments.enforceStrings ) );
		s.append( serializeOneToOneProperties( enforceStrings = arguments.enforceStrings ) );
		s.append( serializeOneToManyProperties( enforceStrings = arguments.enforceStrings ) );
		return s;
	}


	/*
	 * -------------------------- PRIVATE METHODS --------------------------
	 */


	/**
	 * @hint Returns the populated Bean as serialized JSON string
	 */
	private string function serializeAsJson()
	{
		var payload = this.serialize();
		var serialized = serializeJson( payload );
		return removeChar2( serialized );
	}


	/**
	 * @hint Creates a STRUCT of the simple properties defintion with key names.
	 */
	public struct function returnNamedSimpleProperties()
	{
		var namedSimpleProperties = {};
		var simpleProperties = variables.categorizedProperties[ "simple" ];
		for ( var element in simpleProperties )
		{
			namedSimpleProperties[ element.name ] = element;
		}
		return namedSimpleProperties;
	}


	/**
	 * @hint Returns a cf_sql_type type based on the key jsonType.
	 */
	private string function returnPropertyCfsqltype
	( required string property )
	{
		var cfsqltype = "";
		switch ( variables.namedSimpleProperties[ arguments.property ].jsonType )
		{
			case "string":
				cfsqltype = "cf_sql_varchar";
			break;
			case "number":
				cfsqltype = "cf_sql_integer";
			break;
			case "date":
				cfsqltype = "cf_sql_date";
			break;
			case "boolean":
				cfsqltype = "cf_sql_bit";
			break;
		}
		return cfsqltype;
	}


	/**
	 * @hint Friendlier format of the validation errors
	 * @validationResults A list of cbValidator objects
	 * @context Used for recursive validations to know the calling Bean
	 */
	private any function returnFriendlyErrors
	(
		required array validationResults,
		string context = ""
	)
	{
		var errors = {};
		var fieldName = "";
		// loop through the cbValidator objects and turn them into friendlier errors
		for ( var error in arguments.validationResults )
		{
			fieldName = error.getField();
			if ( arguments.context.len() )
				fieldName = arguments.context & "." & fieldName
			;
			if ( ! errors.keyExists( fieldName ) )
				errors[ fieldName ] = []
			;
			errors[ fieldName ].append
			(
				{
					"type" = error.getValidationType().lcase(),
					"data" = listFindNoCase( "udf,optionalUdf", error.getValidationType().lcase() ) ? "Custom function" : error.getValidationData(),
					"message" = error.getMessage()
				}
			);
		}
		return errors;
	}


	/**
	 * @hint Returns all the properties of a category, like SIMPLE, ONE-TO-ONE and ONE-TO-MANY
	 * @type The category to filter the properties by
	 */
	private array function returnPropertiesByType
	( required string type )
	{
		var propertiesByType = variables.categorizedProperties[ type ];
		var properties = [];
		for ( var property in propertiesByType )
		{
			properties.append( property.name );
		}
		return properties;
	}


	/**
	 * @hint Uses the vbValidator for validating the Bean
	 * @context Used for recursive validations to know the calling Bean
	 */
	private any function validateSimpleProperties
	( string context = "" )
	{
		var cbValidator = wirebox.getInstance( "ValidationManager@cbvalidation" );
		var validationResults = cbValidator.validate
		(
			target = this,
			fields = variables.populatedProperties.toList()
		);
		var errors = returnFriendlyErrors
		(
			validationResults = validationResults.getErrors(),
			context = arguments.context
		);
		return errors;
	}


	private any function validateDirectProperties
	( string context = "" )
	{
		var cbValidator = wirebox.getInstance( "ValidationManager@cbvalidation" );
		var properties = returnPropertiesByType( "direct" );
		var errors = {};
		var validationResults = "";
		for ( var property in properties )
		{
			validationResults = cbValidator.validate( target = variables[ property ] );
			errors.append
			(
				returnFriendlyErrors
				(
					validationResults = validationResults.getErrors(),
					context = arguments.context
				)
			);
		}
		return errors;
	}


	/**
	 * @hint Calls the Bean cbValidator recursively
	 * @context Used for recursive validations to know the calling Bean
	 */
	private any function validateOneToOneProperties
	( string context = "" )
	{
		var properties = returnPropertiesByType( "one-to-one" );
		var errors = {};
		for ( var property in properties )
		{
			errors.append( variables[ property ].validate( context = property ) );
		}
		return errors;
	}


	/**
	 * @hint Calls the Bean cbValidator recursively
	 * @context Used for recursive validations to know the calling Bean
	 */
	private any function validateOneToManyProperties
	( string context = "" )
	{
		var properties = returnPropertiesByType( "one-to-many" );
		var errors = {};
		for ( var property in properties )
		{
			if ( variables.keyExists( property ) )
			{
				for ( var i=1; i <= variables[ property ].len(); i++ )
				{
					nestedErrors = variables[ property ][ i ].validate( context = property & "[" & i & "]" );
					if ( nestedErrors.count() )
						errors.append( nestedErrors )
					;
				}
			}
		}
		return errors;
	}


	/**
	 * @hint If a key has a REQUIRED error then remove all other errors from it
	 * @errors A list of friendly errors that need to be potentially filtered
	 */
	private any function reduceRequiredErrors
	( required struct errors )
	{
		var reducedErrors = {};
		for ( var key in arguments.errors )
		{
			if ( ! reducedErrors.keyExists( key ) )
				reducedErrors[ key ] = []
			;
			for ( var item in arguments.errors[ key ] )
			{
				if ( item.type.lcase() == "required" )
				{
					reducedErrors[ key ] = [ item ];
				}
				else
				{
					reducedErrors[ key ].append( item );
				}
			}
		}
		return reducedErrors;
	}


	/**
	 * @hint Uses underlying Java functionality to change a QUERY into a STRUCT
	 * @memento The query data to transform
	 */
	private struct function queryToStruct
	( required query memento )
	{
		var data = {};
		// get array of query columns in the proper case as defined in the SELECT query
		var queryColumns = arguments.memento.getMetaData().getColumnLabels();
		// loop through the query and construct valid data and nulls
		for ( var column in queryColumns )
		{
			// java hooks for determining if a column is really a NULL
			if ( isQueryColumnNull( qry=arguments.memento, column=column ) )
			{
				data[ column ] = javaCast( "null", 0 );
			}
			else
			{
				data[ column ] = arguments.memento[ column ][ 1 ];
			}
		}
		return data;
	}


	/**
	 * @hint Populates all the simple properties of the Bean
	 * @memento The data to populate with
	 */
	private void function populateSimpleProperties
	( required struct memento )
	{
		var properties = variables.categorizedProperties[ "simple" ];
		// for every key in the memento payload
		for ( var mementoKey in arguments.memento )
		{
			// try to find that key in the Bean properties
			for ( var property in properties )
			{
				// if found
				if
				(
					( property.keyExists( "column" ) && len( property.column ) && property.column == mementoKey )
					||
					( property.name == mementoKey )
				)
				{
					// If the payload has a value then simply assign it to the property
					if ( arguments.memento.keyExists( mementoKey ) )
					{
						variables[ property.name ] = arguments.memento[ mementoKey ];
					}
					// the payload value was a NULL
					else
					{
						variables[ property.name ] = javacast( "null", 0 );
					}
					variables.populatedProperties.append( property.name );
					break;
				}
			}
		}
		// include all the required properties in the fields to validate
		if ( isDefined( "this.constraints" ) )
		{
			for ( var property in properties )
			{
				if
				(
					this.constraints.keyExists( property.name )
					&& this.constraints[ property.name ].keyExists( "required" )
					&& this.constraints[ property.name ].required == true
					&& ! variables.populatedProperties.find( property.name )
				)
				{
					variables.populatedProperties.append( property.name );
				}
			}
		}
	}


	private void function populateDirectProperties
	( required struct memento )
	{
		// get all the one-to-many properties of this Bean
		var properties = variables.categorizedProperties[ "direct" ];
		for ( var mementoKey in arguments.memento )
		{
			// try to find that key in the Bean properties
			for ( var property in properties )
			{
				// if found
				if
				(
					( property.keyExists( "column" ) && len( property.column ) && property.column == mementoKey )
					||
					( property.name == mementoKey )
				)
				{
					// If the payload has a value then simply assign it to the property
					if ( arguments.memento.keyExists( mementoKey ) )
					{
						// instantiate the linked Bean
						var bean = createObject( "component", property.cfc ).init();
						// populate the Bean with the payload specific part
						bean.populate
						(
							{
								"#mementoKey#" = arguments.memento[ mementoKey ]
							}
						);
						// add the linked populated Bean to this Bean's specific property
						variables[ property.name ] = bean;
					}
					// the payload value was a NULL
					else
					{
						variables[ property.name ] = javacast( "null", 0 );
					}
					variables.populatedProperties.append( property.name );
					break;
				}
			}
		}
	}


	/**
	 * @hint Populates all the one-to-one mapped properties of the Bean
	 * @memento The data to populate with
	 */
	private void function populateOneToOneProperties
	( required struct memento )
	{
		// get all the one-to-many properties of this Bean
		var properties = variables.categorizedProperties[ "one-to-one" ];
		for ( var mementoKey in arguments.memento )
		{
			// try to find that key in the Bean properties
			for ( var property in properties )
			{
				// if found
				if
				(
					( property.keyExists( "column" ) && len( property.column ) && property.column == mementoKey )
					||
					( property.name == mementoKey )
				)
				{
					// If the payload has a value then simply assign it to the property
					if ( arguments.memento.keyExists( mementoKey ) )
					{
						// instantiate the linked Bean
						var bean = createObject( "component", property.cfc ).init();
						// populate the Bean with the payload specific part
						bean.populate( arguments.memento[ mementoKey ] );
						// add the linked populated Bean to this Bean's specific property
						variables[ property.name ] = bean;
					}
					// the payload value was a NULL
					else
					{
						variables[ property.name ] = javacast( "null", 0 );
					}
					break;
				}
			}
		}
	}


	/**
	 * @hint Populates the one-to-many properties of the Bean
	 * @memento The data to populate with
	 */
	private void function populateOneToManyProperties
	( required struct memento )
	{
		// get all the one-to-many properties of this Bean
		var properties = variables.categorizedProperties[ "one-to-many" ];
		// local scope
		var bean = "";
		var injectedBeans = [];


		for ( var mementoKey in arguments.memento )
		{
			// try to find that key in the Bean properties
			for ( var property in properties )
			{
				// if found
				if
				(
					( property.keyExists( "column" ) && len( property.column ) && property.column == mementoKey )
					||
					( property.name == mementoKey )
				)
				{
					// If the payload has a value then simply assign it to the property
					if ( arguments.memento.keyExists( mementoKey ) )
					{
						// loop through the payload array for that property
						for ( var mementoItem in arguments.memento[ mementoKey ] )
						{
							// instantiate the linked Bean
							bean = createObject( "component", property.cfc ).init();
							// populate the Bean with the payload specific part
							bean.populate( mementoItem );
							// add the linked populated Bean to this Bean
							injectedBeans.append( bean );
						}
						variables[ property.name ] = injectedBeans;
					}
					// the payload value was a NULL
					else
					{
						variables[ property.name ] = javacast( "null", 0 );
					}
					break;
				}
			}
		}
	}


	/**
	 * @hint Serializes the simple properties of the Bean
	 */
	public struct function serializeSimpleProperties
	( required boolean enforceStrings )
	{
		var out = createObject( "java", "java.util.LinkedHashMap").init();
		var properties = variables.categorizedProperties[ "simple" ];
		var beanFunctions = getMetaData( this ).functions;
		var accessor = "";
		for ( fieldName in properties )
		{
			// exclude any fields that were not populated
			if ( ! variables.populatedProperties.find( fieldName.name ) )
				continue
			;
			// exclude any fields that are marked as non serializable
			if ( fieldName.keyExists( "serializable" ) && fieldName.serializable == false )
				continue
			;
			for ( var beanFunction in beanFunctions )
			{
				/*
					Convention used for overrifing the default getters for a property.
					Usually used for Enumerators.
				 */
				if ( beanFunction.name == "vetoGet" & fieldName.name )
				{
					accessor = "vetoGet" & fieldName.name;
					break;
				}
				else
				{
					accessor = "get" & fieldName.name;
				}
			}
			var getField = this[ accessor ];
			var field = fieldName.name;
			var fieldValue = getField();
			var nullField = isNull( fieldValue );
			var jsonContent = "";
			if ( isNull( fieldValue ) )
			{
				out[ field ] = javacast( "null", 0 );
			}
			else
			{
				out[ field ] = getField();
				if ( fieldName.keyExists( "jsonType" ) )
				{
					switch ( fieldName.jsonType )
					{
						case "string":
							if ( arguments.enforceStrings == true )
								out[ field ] = chr( 2 ) & out[ field ]
							;
						break;
						case "number":
							if ( isBoolean( out[ field ] ) )
							{
								out[ field ] ? 1 : 0;
							}
							else
							{
								out[ field ] = out[ field ];
							}
						break;
						case "date":
							out[ field ] = returnIsoTimeString( out[ field ] );
						break;
						case "boolean":
							out[ field ] = out[ field ] ? true : false;
						break;
					}
				}
			}
		}
		return out;
	}


	private any function serializeDirectProperties
	( required boolean enforceStrings )
	{
		var properties = returnPropertiesByType( "direct" );
		var out = createObject( "java", "java.util.LinkedHashMap").init();
		for ( var property in properties )
		{
			if  ( variables.keyExists( property ) )
			{
				out.append( variables[ property ].serializeSimpleProperties( enforceStrings = arguments.enforceStrings ) );
			}
			else
			{
				out[ property ] = javacast( "null", 0 );
			}
		}
		return out;
	}


	/**
	 * @hint Serializes mapped one-to-one Bean properties
	 */
	private any function serializeOneToOneProperties
	( required boolean enforceStrings )
	{
		var properties = returnPropertiesByType( "one-to-one" );
		var out = createObject( "java", "java.util.LinkedHashMap").init();
		for ( var property in properties )
		{
			if  ( variables.keyExists( property ) )
			{
				out[ property ] = variables[ property ].serialize( enforceStrings = arguments.enforceStrings );
			}
			else
			{
				out[ property ] = javacast( "null", 0 );
			}
		}
		return out;
	}


	private any function serializeOneToManyProperties
	( required boolean enforceStrings )
	{
		var properties = returnPropertiesByType( "one-to-many" );
		var out = createObject( "java", "java.util.LinkedHashMap").init();
		for ( var property in properties )
		{
			if  ( variables.keyExists( property ) )
			{
				out[ property ] = [];
				for ( propertyArray in variables[ property ] )
				{
					out[ property ].append( propertyArray.serialize( enforceStrings = arguments.enforceStrings ) );
				}
			}
			else
			{
				out[ property ] = javacast( "null", 0 );
			}
		}
		return out;
	}


	/**
	 * @hint Returns the Bean properties categorized into SIMPLE, ONE-TO-ONE and ONE-TO-MANY groups
	 */
	private struct function returnCategorizedProperties()
	{
		// structure of the returned properties
		var categorizedProperties = {
			"simple" = [],
			"direct" = [],
			"one-to-one" = [],
			"one-to-many" = []
		};
		// get all properties regardless
		var properties = getMetaData( this ).properties;
		for ( var property in properties )
		{
			// exclude any properties that are injected
			if ( ! property.keyExists( "inject") )
			{
				property.keyExists( "fieldtype" )
					? categorizedProperties[ property.fieldtype ].append( property )
					: categorizedProperties[ "simple" ].append( property )
				;
			}
		}
		return categorizedProperties;
	}


	/**
	 * @hint Formats a date into the ISO-8601 format
	 */
	private string function returnIsoTimeString
	(
		string datetime = "",
		boolean convertToUTC = true
	)
	{
		if ( len(arguments.dateTime ) )
		{
			if ( convertToUTC )
				arguments.datetime = dateConvert( "local2utc", arguments.datetime )
			;
			// When formatting the time, make sure to use "HH" so that the
			// time is formatted using 24-hour time.
			return
			(
				dateFormat( arguments.datetime, "yyyy-mm-dd" ) &
				"T" &
				timeFormat( arguments.datetime, "HH:mm:ss" ) &
				"Z"
			);
		}
		else
		{
			//return arguments.dateTime;
			return javacast( "null", 0 );
		}
	}


	/**
	 * @hint Java underlying checks for a query NULL value in a column
	 * @qry The query to check against
	 * @column The column name in the query
	 * @row The row to check against
	 */
	private any function IsQueryColumnNull
	(
		required query qry,
		required string column,
		numeric row = 1
	)
	{
		var cacheRow = arguments.qry.currentRow;
		arguments.qry.absolute( row );
		var value = arguments.qry.getObject( column );
		var valueIsNull = arguments.qry.wasNull();
		arguments.qry.absolute( cacheRow );
		return valueIsNull;
	}


	private any function removeBeginningChar2
	( required any value )
	{


		if ( ! isNull( arguments.value ) && left( arguments.value, 1 ) == chr( 2 ) )
		{
			if ( arguments.value.len() == 1 )
			{
				return "";
			}
			else
			{
				return arguments.value.right( len( arguments.value ) - 1 );
			}
		}
		else
		{
			return arguments.value;
		}
	}


	private any function removeChar2
	( required any value )
	{
		if ( isNull( arguments.value ) )
		{
			return arguments.value;
		}
		else
		{
			return replaceNoCase( arguments.value, chr( 2 ), "", "all" );
		}
	}


}