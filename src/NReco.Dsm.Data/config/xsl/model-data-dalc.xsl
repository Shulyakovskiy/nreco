<!--
NReco library (http://nreco.googlecode.com/)
Copyright 2008-2014 Vitaliy Fedorchenko
Distributed under the LGPL licence
 
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
-->	
<xsl:stylesheet version='1.0' 
				xmlns:xsl='http://www.w3.org/1999/XSL/Transform' 
				xmlns:msxsl="urn:schemas-microsoft-com:xslt" 
				xmlns:nnd="urn:schemas-nreco:data:dalc:v2"
				xmlns="urn:schemas-nicnet:ioc:v2"
				exclude-result-prefixes="nnd msxsl">
				
<xsl:output method='xml' indent='yes' />

<xsl:template match='nnd:model'>
	<components>
		<xsl:apply-templates select='nnd:*'/>
	</components>
</xsl:template>

<!-- DB Data Access Layer Components set -->
<xsl:template match='nnd:db-dalc'>
	<xsl:param name="dalcName">
		<xsl:choose>
			<xsl:when test="@name"><xsl:value-of select="@name"/></xsl:when>
			<xsl:otherwise><xsl:message terminate = "yes">DB DALC name is required</xsl:message></xsl:otherwise>
		</xsl:choose>
	</xsl:param>
	<xsl:param name="permissionsEnabled">
		<xsl:choose>
			<xsl:when test="nnd:permissions">True</xsl:when>
			<xsl:otherwise>False</xsl:otherwise>
		</xsl:choose>
	</xsl:param>
	
	<xsl:variable name="dataviewsEnabled">
		<xsl:choose>
			<xsl:when test="count(nnd:dataviews/*)>0">True</xsl:when>
			<xsl:otherwise>False</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	
	<xsl:apply-templates select="nnd:driver/*" mode="db-dalc-driver">
		<xsl:with-param name="dalcName" select="$dalcName"/>
	</xsl:apply-templates>
	
	<component name="{$dalcName}-DbDalcCommandGenerator" singleton="true" lazy-init="true">
		<xsl:attribute name="type">
			<xsl:choose>
				<xsl:when test="$permissionsEnabled='True'">NI.Data.Permissions.DbPermissionCommandGenerator,NI.Data</xsl:when>
				<xsl:otherwise>NI.Data.DbCommandGenerator,NI.Data</xsl:otherwise>
			</xsl:choose>
		</xsl:attribute>
		<constructor-arg name="dbFactory"><ref name="{$dalcName}-DbDalcFactory"/></constructor-arg>
		<constructor-arg name="views">
			<list>
				<xsl:for-each select="nnd:dataviews/nnd:*">
					<entry>
						<xsl:apply-templates select="." mode="db-dalc-dataview"/>
					</entry>
				</xsl:for-each>				
			</list>
		</constructor-arg>
		<xsl:if test="$permissionsEnabled='True'">
			<property name="Rules">
				<xsl:for-each select="nnd:permissions/*">
					<entry>
						<xsl:apply-templates select="." mode="db-dalc-permission-rule"/>
					</entry>
				</xsl:for-each>						
			</property>
		</xsl:if>
	</component>
	
	<!-- define DB dalc -->
	<component name="{$dalcName}" type="NI.Data.DbDalc,NI.Data" singleton="true" lazy-init="true">
		<constructor-arg name="factory"><ref name="{$dalcName}-DbDalcFactory"/></constructor-arg>
		<constructor-arg name="connection"><ref name="{$dalcName}-DbConnection"/></constructor-arg>
		<constructor-arg name="cmdGenerator"><ref name="{$dalcName}-DbDalcCommandGenerator"/></constructor-arg>
	</component>
		
	<component name="{$dalcName}-EventBroker" type="NI.Data.DataEventBroker,NI.Data" singleton="true" lazy-init="true">
		<constructor-arg index="0"><ref name="{$dalcName}"/></constructor-arg>
	</component>
	
	<xsl:for-each select="nnd:triggers/nnd:*">
		<xsl:apply-templates select="." mode="db-dalc-trigger">
			<xsl:with-param name="eventBrokerName"><xsl:value-of select="$dalcName"/>-EventBroker</xsl:with-param>
			<xsl:with-param name="dalcName" select="$dalcName"/>
			<!-- ensure that trigger names are really unique -->
			<xsl:with-param name="namePrefix"><xsl:value-of select="$dalcName"/>-<xsl:value-of select="generate-id(.)"/>-</xsl:with-param>
		</xsl:apply-templates>
	</xsl:for-each>
	
</xsl:template>

<xsl:template match="nnd:view" mode="db-dalc-dataview">
	<xsl:param name="viewName">
		<xsl:choose>
			<xsl:when test="@name"><xsl:value-of select="@name"/></xsl:when>
			<xsl:when test="name"><xsl:value-of select="name"/></xsl:when>
			<xsl:otherwise><xsl:message terminate = "yes">DB View name is required</xsl:message></xsl:otherwise>
		</xsl:choose>
	</xsl:param>
	<xsl:param name="viewOriginInfo">
		<xsl:choose>
			<xsl:when test="@origin"><xsl:value-of select="@origin"/></xsl:when>
			<xsl:when test="count(nnd:origin/nnd:sourcename)>0">
				<xsl:for-each select="nnd:origin/nnd:sourcename"><xsl:if test="position()>1">,</xsl:if><xsl:apply-templates select="." mode="db-dalc-dataview-origin-entry"/></xsl:for-each>
			</xsl:when>
			<xsl:when test="nnd:origin"><xsl:value-of select="nnd:origin"/></xsl:when>
		</xsl:choose>
	</xsl:param>
	<xsl:param name="fieldsCount">
		<xsl:choose>
			<xsl:when test="nnd:fields/nnd:count"><xsl:value-of select="nnd:fields/nnd:count"/></xsl:when>
			<xsl:otherwise>count(*)</xsl:otherwise>
		</xsl:choose>
	</xsl:param>
	<xsl:param name="fields">
		<xsl:choose>
			<xsl:when test="nnd:fields/nnd:select"><xsl:value-of select="nnd:fields/nnd:select"/></xsl:when>
			<xsl:otherwise>*</xsl:otherwise>
		</xsl:choose>
	</xsl:param>
	<xsl:param name="sql">
		<xsl:choose>
			<xsl:when test="@sql"><xsl:value-of select="@sql"/></xsl:when>
			<xsl:when test="nnd:sql"><xsl:value-of select="nnd:sql"/></xsl:when>
			<xsl:otherwise><xsl:message terminate = "yes">SQL Text is required</xsl:message></xsl:otherwise>
		</xsl:choose>
	</xsl:param>
	<xsl:param name="defaultExprResolverName"/>
	<xsl:variable name="exprResolver">
		<xsl:choose>
			<xsl:when test="@resolver"><ref name="{@resolver}"/></xsl:when>
			<xsl:otherwise><ref name="{$defaultExprResolverName}"/></xsl:otherwise>
		</xsl:choose>
	</xsl:variable>

	<component type="NI.Data.DbDalcView,NI.Data" singleton="false">
		<constructor-arg name="tableName"><value><xsl:value-of select="$viewName"/></value></constructor-arg>
		<constructor-arg name="sqlCommandTextTemplate"><value><xsl:value-of select="$sql"/></value></constructor-arg>
		<constructor-arg name="sqlFields"><value><xsl:value-of select="$fields"/></value></constructor-arg>
		<constructor-arg name="sqlCountFields"><value><xsl:value-of select="$fieldsCount"/></value></constructor-arg>

		<xsl:if test="nnd:origin">
			<property name="OriginTables">
				<list>
					<xsl:for-each select="nnd:origin">
						<entry>
							<component type="NI.Data.QTable,NI.Data" singleton="false">
								<constructor-arg index="0"><value><xsl:value-of select="."/></value></constructor-arg>
							</component>
						</entry>
					</xsl:for-each>
				</list>
			</property>
		</xsl:if>

		<xsl:if test="nnd:fields/nnd:mapping">
			<property name="FieldMapping">
				<map>
					<xsl:for-each select="nnd:fields/nnd:mapping/nnd:field">
						<entry key="{@name}">
							<value><xsl:value-of select="."/></value>
						</entry>
					</xsl:for-each>
				</map>
			</property>
		</xsl:if>

	</component>

</xsl:template>

<xsl:template match="nnd:ref" mode="db-dalc-dataview">
	<ref name="{@name}"/>
</xsl:template>

<xsl:template name="db-dalc-get-connection-string">
	<xsl:choose>
		<xsl:when test="nnd:connection/@string">
			<value><xsl:value-of select="nnd:connection/@string"/></value>
		</xsl:when>
		<xsl:when test="nnd:connection/nnd:string/@name">
			<component type="NI.Winter.PropertyInvokingFactory" singleton="false">
				<property name="TargetProperty"><value>ConnectionString</value></property>
				<property name="TargetObject">
					<component type="NI.Winter.MethodInvokingFactory" singleton="false">
						<property name="TargetMethod"><value>get_Item</value></property>
						<property name="TargetMethodArgTypes">
							<list>
								<entry><type>System.String,mscorlib</type></entry>
							</list>
						</property>
						<property name="TargetMethodArgs">
							<list>
								<entry>
									<value><xsl:value-of select="nnd:connection/nnd:string/@name"/></value>
								</entry>
							</list>
						</property>
						<property name="TargetObject">
							<component type="NI.Winter.StaticPropertyInvokingFactory" singleton="false">
								<property name="TargetType"><type>System.Configuration.ConfigurationManager,System.Configuration</type></property>
								<property name="TargetProperty"><value>ConnectionStrings</value></property>
							</component>
						</property>
					</component>
				</property>
			</component>
		</xsl:when>
		<xsl:when test="nnd:connection/nnd:string">
			<value><xsl:value-of select="nnd:connection/nnd:string"/></value>
		</xsl:when>
		<xsl:when test="nnd:connection/node() and not(nnd:connection/text())">
			<xsl:apply-templates select="nnd:connection/node()"/>
		</xsl:when>			
		<xsl:otherwise>
			<xsl:message terminate = "yes">Connection string is required</xsl:message>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<xsl:template match="nnd:mssql" mode="db-dalc-driver">
	<xsl:param name="dalcName"/>
	<xsl:param name="connectionString">
		<xsl:call-template name="db-dalc-get-connection-string"/>
	</xsl:param>
	<xsl:variable name="top-optimization">
		<xsl:choose>
			<xsl:when test="@top-optimization='1' or @top-optimization='true'">True</xsl:when>
			<xsl:otherwise></xsl:otherwise>
		</xsl:choose>
	</xsl:variable>	
	<xsl:variable name="const-optimization">
		<xsl:choose>
			<xsl:when test="@const-optimization='1' or @const-optimization='true'">True</xsl:when>
			<xsl:otherwise></xsl:otherwise>
		</xsl:choose>
	</xsl:variable>		
	<xsl:variable name="name-in-brackets">
		<xsl:choose>
			<xsl:when test="@name-in-brackets='1' or @name-in-brackets='true'">True</xsl:when>
			<xsl:otherwise></xsl:otherwise>
		</xsl:choose>
	</xsl:variable>		
	
	<component name="{$dalcName}-DbDalcFactory" type="NI.Data.SqlClient.SqlClientDalcFactory,NI.Data" singleton="true" lazy-init="true">
		<xsl:if test="$top-optimization='True'">
			<property name="TopOptimization">
				<value><xsl:value-of select="$top-optimization"/></value>
			</property>
		</xsl:if>
		<xsl:if test="$const-optimization='True'">
			<property name="ConstOptimization">
				<value><xsl:value-of select="$const-optimization"/></value>
			</property>
		</xsl:if>
		<xsl:if test="$name-in-brackets='True'">
			<property name="NameBrackets">
				<value><xsl:value-of select="$name-in-brackets"/></value>
			</property>		
		</xsl:if>
		<xsl:if test="@command-timeout">
			<property name="CommandTimeout"><value><xsl:value-of select="@command-timeout"/></value></property>  
		</xsl:if>
	</component>
	<component name="{$dalcName}-DbConnection" type="System.Data.SqlClient.SqlConnection,System.Data" singleton="true" lazy-init="true">
		<property name="ConnectionString">
			<xsl:copy-of select="msxsl:node-set($connectionString)/*"/>
		</property>
	</component>
</xsl:template>

<xsl:template match="nnd:mysql" mode="db-dalc-driver">
	<xsl:param name="dalcName"/>
	<xsl:param name="connectionString">
		<xsl:call-template name="db-dalc-get-connection-string"/>
	</xsl:param>
	<component name="{$dalcName}-DbDalcFactory" type="NI.Data.MySql.MySqlDalcFactory,NI.Data.MySql" singleton="true" lazy-init="true"/>
	<component name="{$dalcName}-DbConnection" type="MySql.Data.MySqlClient.MySqlConnection,MySql.Data" singleton="true" lazy-init="true">
		<property name="ConnectionString">
			<xsl:copy-of select="msxsl:node-set($connectionString)/*"/>
		</property>
	</component>
</xsl:template>

<xsl:template match="nnd:rule" mode="db-dalc-permission-rule">
	<xsl:param name="tableName">
		<xsl:choose>
			<xsl:when test="@table"><xsl:value-of select="@sourcename"/></xsl:when>
			<xsl:otherwise><xsl:message terminate = "yes">rule/@name is required</xsl:message></xsl:otherwise>
		</xsl:choose>
	</xsl:param>
	<xsl:param name="operation">
		<xsl:choose>
			<xsl:when test="@operation"><xsl:value-of select="@operation"/></xsl:when>
			<xsl:otherwise><xsl:message terminate = "yes">rule/@operation</xsl:message></xsl:otherwise>
		</xsl:choose>
	</xsl:param>
	<xsl:param name="condition">
		<xsl:choose>
			<xsl:when test="nnd:condition"><xsl:value-of select="nnd:condition"/></xsl:when>
			<xsl:otherwise><xsl:message terminate = "yes">rule/condition</xsl:message></xsl:otherwise>
		</xsl:choose>
	</xsl:param>

	<component type="NI.Data.Permissions.QueryRule,NI.Data" singleton="false">
		<constructor-arg name="tableName"><value><xsl:value-of select="$tableName"/></value></constructor-arg>
		<constructor-arg name="op"><value><xsl:value-of select="$operation"/></value></constructor-arg>
		<constructor-arg name="relexCondition"><value><xsl:value-of select="condition"/></value></constructor-arg>
		<xsl:if test="nnd:match/nnd:view">
			<property name="ViewNames">
				<list>
					<xsl:for-each select="nnd:match/nnd:view">
						<entry>
							<component type="NI.Data.QTable,NI.Data" singleton="false">
								<constructor-arg index="0"><value><xsl:value-of select="."/></value></constructor-arg>
							</component>
						</entry>
					</xsl:for-each>
				</list>
			</property>
		</xsl:if>
	</component>

</xsl:template>

<xsl:template match="nnd:trace" mode="db-dalc-trigger">
	<xsl:param name="namePrefix"/>
	<xsl:param name="eventBrokerName"/>
	<component name="{$namePrefix}TraceTrigger" type="NI.Data.Triggers.SqlCommandTraceTrigger,NI.Data" singleton="true" lazy-init="false">
		<constructor-arg index="0"><ref name="{$eventBrokerName}"/></constructor-arg>
	</component>
</xsl:template>

<xsl:template match="nnd:datarow" mode="db-dalc-trigger">
	<xsl:param name="eventBrokerName"/>
	<xsl:param name="namePrefix"/>
	<xsl:call-template name="db-dalc-datarow-trigger">
		<xsl:with-param name="eventBrokerName" select="$eventBrokerName"/>
		<xsl:with-param name="namePrefix" select="$namePrefix"/>
	</xsl:call-template>
</xsl:template>

<xsl:template name="db-dalc-datarow-trigger">
	<xsl:param name="namePrefix"/>
	<xsl:param name="eventBrokerName"/>

	<xsl:param name="action">
		<xsl:choose>
			<xsl:when test="@action"><xsl:value-of select="@action"/></xsl:when>
		</xsl:choose>
	</xsl:param>
	<xsl:param name="triggerName">
		<xsl:choose>
			<xsl:when test="@name"><xsl:value-of select="@name"/></xsl:when>
			<xsl:otherwise><xsl:value-of select="$namePrefix"/>DataRowTrigger-<xsl:value-of select="generate-id(.)"/></xsl:otherwise>
		</xsl:choose>
	</xsl:param>
	<xsl:param name="tableName">
		<xsl:choose>
			<xsl:when test="@table"><xsl:value-of select="@table"/></xsl:when>
		</xsl:choose>
	</xsl:param>
	
	<component name="{$triggerName}" type="NI.Data.Triggers.DataRowTrigger,NI.Data" singleton="true" lazy-init="false">
		<constructor-arg name="broker"><ref name="{$eventBrokerName}"/></constructor-arg>
		<constructor-arg name="rowAction"><value><xsl:value-of select="$action"/></value></constructor-arg>
		<constructor-arg name="tableName"><value><xsl:value-of select="$tableName"/></value></constructor-arg>
		<constructor-arg name="handler"><xsl:copy-of select="nnd:handler/node()"/></constructor-arg>
	</component>
	
</xsl:template>

<xsl:template match="nnd:invalidate-data-dependency" mode="db-dalc-trigger">
	<xsl:param name="namePrefix"/>
	<xsl:param name="eventBrokerName"/>
	<xsl:param name="dalcName"/>

	<xsl:param name="triggerName">
		<xsl:choose>
			<xsl:when test="@name"><xsl:value-of select="@name"/></xsl:when>
			<xsl:otherwise><xsl:value-of select="$namePrefix"/>InvalidateDataDependencyTrigger-<xsl:value-of select="generate-id(.)"/></xsl:otherwise>
		</xsl:choose>
	</xsl:param>

	<component name="{$triggerName}" type="NI.Data.Web.InvalidateDataDependencyTrigger,NI.Data" singleton="true" lazy-init="false">
		<constructor-arg index="0"><value><xsl:value-of select="$dalcName"/></value></constructor-arg>
		<constructor-arg index="1"><ref name="{$eventBrokerName}"/></constructor-arg>
	</component>
</xsl:template>

	<!--xsl:template match="nr:relex" mode="nreco-provider" name="relex-query-provider">
	<xsl:param name="name"/>
	<xsl:param name="expression" select="text()"/> 
	<xsl:param name="sort" select="@sort"/>
	<xsl:param name="resolver">
		<xsl:choose>
			<xsl:when test="@resolver"><xsl:value-of select="@resolver"/></xsl:when>
			<xsl:otherwise><xsl:value-of select="$default-expression-resolver"/></xsl:otherwise>
		</xsl:choose>
	</xsl:param>

	<xsl:call-template name='component-definition'>
		<xsl:with-param name='name' select='$name'/>
		<xsl:with-param name='type'>NI.Data.RelationalExpressions.RelExQueryProvider</xsl:with-param>
		<xsl:with-param name='injections'>
			<property name="ExprResolver"><ref name="{$resolver}"/></property>
			<property name="RelEx"><value><xsl:value-of select="$expression"/></value></property>
			<xsl:if test="not($sort='') and $sort">
				<property name="SortProvider">
					<component type='NReco.Composition.ConstProvider' singleton='false'>
						<constructor-arg index='0'>
							<xsl:choose>
								<xsl:when test="contains($sort,',')">
									<list>
										<xsl:call-template name="relex-query-sort-generate-list">
											<xsl:with-param name="input" select="$sort"/>
										</xsl:call-template>
									</list>
								</xsl:when>
								<xsl:otherwise>
									<value><xsl:value-of select="$sort"/></value>
								</xsl:otherwise>
							</xsl:choose>
						</constructor-arg>
					</component>
				</property>
			</xsl:if>
			<xsl:if test="nr:extended-properties/node()">
				<property name="ExtendedPropertiesProvider">
					<xsl:apply-templates select="nr:extended-properties/node()" mode="nreco-provider"/>
				</property>
			</xsl:if>			
			<property name="RelExQueryParser">
				<component type="NI.Data.RelationalExpressions.RelExQueryParser,NI.Data.RelationalExpressions" singleton="false">
					<property name="AllowDumpConstants"><value>false</value></property>
				</component>
			</property>
		</xsl:with-param>
	</xsl:call-template>
</xsl:template>

<xsl:template match="nr:relex-condition" mode="nreco-provider" name="relex-query-condition-provider">
	<xsl:param name="name"/>
	<xsl:param name="expression" select="."/> 
	<xsl:param name="resolver">
		<xsl:choose>
			<xsl:when test="@resolver"><xsl:value-of select="@resolver"/></xsl:when>
			<xsl:otherwise><xsl:value-of select="$default-expression-resolver"/></xsl:otherwise>
		</xsl:choose>
	</xsl:param>
	<xsl:call-template name='component-definition'>
		<xsl:with-param name='name' select='$name'/>
		<xsl:with-param name='type'>NI.Data.RelationalExpressions.RelExQueryNodeProvider</xsl:with-param>
		<xsl:with-param name='injections'>
			<property name="ExprResolver"><ref name="{$resolver}"/></property>
			<property name="RelExCondition"><value><xsl:value-of select="$expression"/></value></property>
			<property name="RelExQueryParser">
				<component type="NI.Data.RelationalExpressions.RelExQueryParser,NI.Data.RelationalExpressions" singleton="false">
					<property name="AllowDumpConstants"><value>false</value></property>
				</component>
			</property>
		</xsl:with-param>
	</xsl:call-template>
</xsl:template-->

<xsl:template name="relex-query-sort-generate-list">
	<xsl:param name="input"/>
	<xsl:variable name="sortFld" select="substring-before($input, ',')"/>
	<xsl:variable name="tail" select="substring-after($input, ',')"/>
	<entry><value><xsl:value-of select="$sortFld"/></value></entry>
	<xsl:if test="contains($tail,',')">
		<xsl:call-template name="relex-query-sort-generate-list">
			<xsl:with-param name="input" select="substring-after($input, ',')"/>
		</xsl:call-template>
	</xsl:if>
	<xsl:if test="not(contains($tail,','))">
		<entry><value><xsl:value-of select="$tail"/></value></entry>
	</xsl:if>
</xsl:template>


<!--xsl:template match="nr:dalc" mode="nreco-provider">
	<xsl:param name="name"/>
	<xsl:param name="result">
		<xsl:choose>
			<xsl:when test="@result"><xsl:value-of select="@result"/></xsl:when>
			<xsl:otherwise>object</xsl:otherwise>
		</xsl:choose>
	</xsl:param>
	<xsl:param name="dalc">
		<xsl:choose>
			<xsl:when test="@from"><xsl:value-of select="@from"/></xsl:when>
			<xsl:otherwise>
				<xsl:message terminate = "yes">Reference to DALC is required</xsl:message>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:param>
	<xsl:param name="query">
		<xsl:choose>
			<xsl:when test="@query">
				<nr:relex><xsl:value-of select="@query"/></nr:relex>
			</xsl:when>
			<xsl:when test="count(nr:query/*)>0"><xsl:copy-of select="nr:query/node()"/></xsl:when>
			<xsl:when test="nr:query">
				<xsl:for-each select="nr:query">
					<nr:relex>
						<xsl:if test="@sort">
							<xsl:attribute name="sort"><xsl:value-of select="@sort"/></xsl:attribute>
						</xsl:if>
						<xsl:value-of select="."/>
					</nr:relex>
				</xsl:for-each>
			</xsl:when>
			<xsl:otherwise>
				<xsl:message terminate = "yes">Query is required</xsl:message>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:param>

	<xsl:call-template name='component-definition'>
		<xsl:with-param name='name' select='$name'/>
		<xsl:with-param name='type'>
			<xsl:choose>
				<xsl:when test="$result='object'">NI.Data.Dalc.DalcObjectProvider,NI.Data.Dalc</xsl:when>
				<xsl:when test="$result='record'">NI.Data.Dalc.DalcRecordDictionaryProvider,NI.Data.Dalc</xsl:when>
				<xsl:when test="$result='list'">NI.Data.Dalc.DalcObjectListProvider,NI.Data.Dalc</xsl:when>
				<xsl:when test="$result='recordlist'">NI.Data.Dalc.DalcDictionaryListProvider,NI.Data.Dalc</xsl:when>
				<xsl:when test="$result='dataset'">NI.Data.Dalc.DalcDataSetProvider,NI.Data.Dalc</xsl:when>
			</xsl:choose>
		</xsl:with-param>
		<xsl:with-param name='injections'>
			<xsl:choose>
				<xsl:when test="$result='dataset'">
					<property name="QueryProviders">
						<list>
							<xsl:for-each select="msxsl:node-set($query)/node()">
								<entry>
									<xsl:apply-templates select="." mode="nreco-provider"/>
								</entry>
							</xsl:for-each>
						</list>
					</property>
				</xsl:when>
				<xsl:otherwise>
					<property name="QueryProvider">
						<xsl:if test="count(msxsl:node-set($query)/*)>0">
							<xsl:apply-templates select="msxsl:node-set($query)/node()[position()=1]" mode="nreco-provider"/>
						</xsl:if>
					</property>					
				</xsl:otherwise>
			</xsl:choose>

			<property name="Dalc"><ref name="{$dalc}"/></property>
		</xsl:with-param>
	</xsl:call-template>
</xsl:template-->

	
</xsl:stylesheet>