require 'rexml/document'
require 'rdf'
require 'rdf/turtle'
require 'json/ld'
include RDF

dateTypes = {
  "creation"          => "https://raw.githubusercontent.com/OmicsDI-RDF/RDF/master/odio.owl#Creation",
  "export"            => "https://raw.githubusercontent.com/OmicsDI-RDF/RDF/master/odio.owl#Export",
  "last_modification" => "https://raw.githubusercontent.com/OmicsDI-RDF/RDF/master/odio.owl#LastModification",
  "output"            => "https://raw.githubusercontent.com/OmicsDI-RDF/RDF/master/odio.owl#Output",
  "publication"       => "https://raw.githubusercontent.com/OmicsDI-RDF/RDF/master/odio.owl#Publication",
  "submission"        => "https://raw.githubusercontent.com/OmicsDI-RDF/RDF/master/odio.owl#Submission",
  "updated"           => "https://raw.githubusercontent.com/OmicsDI-RDF/RDF/master/odio.owl#Updated"
}

dbNames = {
  "ChEBI"        => ["http://identifiers.org/chebi/", "http://purl.obolibrary.org/obo/"], # CHEBI:36927 for idorg, CHEBI_36927 for obo
  "EGA"          => ["http://identifiers.org/ega.dataset/", "https://www.ebi.ac.uk/ega/datasets/"], # EGAD00000000001 URI for EGAD (datasets) is here
  "Ensembl"      => ["http://identifiers.org/ensembl/", "http://www.ensembl.org/id/"],    # ENSG00000139618
  "FlyBase"      => ["http://identifiers.org/flybase/", "http://flybase.org/reports/"],   # FBgn0011293
  "HMDB"         => ["http://identifiers.org/hmdb/", "http://www.hmdb.ca/metabolites/"],  # HMDB00001
  "IPI"          => ["http://identifiers.org/ipi/", "http://www.ebi.ac.uk/Tools/dbfetch/dbfetch?db=ipi&id="], # IPI00000001 DEPRECATED
  "InsectBase"   => [nil, nil], # e.g. GB49871 in PeptideAtlas but unknown URL
  "KEGG"         => ["http://identifiers.org/kegg.compound/", "http://www.kegg.jp/entry/"], # C00670
  "MetaboLights" => ["http://identifiers.org/metabolights/", "http://www.ebi.ac.uk/metabolights/"], # MTBLS1
  "NCBI"         => ["http://identifiers.org/ncbiprotein/", "https://www.ncbi.nlm.nih.gov/protein/"], # 148747492 NCBI protein?
  "PASS"         => [nil, "http://www.peptideatlas.org/PASS/"], # PASS00275 not in idorg
  #"PRIDE"        => [],
  #"PubChem"      => [],
  #"SGD"          => [],
  "TAXONOMY"     => ["http://identifiers.org/taxonomy/", "http://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?mode=Info&id="], # 9606
  "UniProt"      => ["http://identifiers.org/uniprot/", "http://www.uniprot.org/uniprot/"], # P62158
  "Unknown"      => [nil, nil],
  #"WormGene"     => [],
  "arrayexpress" => ["http://identifiers.org/arrayexpress/", "http://www.ebi.ac.uk/arrayexpress/experiments/"], # E-MEXP-1712
  "ensembl"      => ["http://identifiers.org/ensembl/", "http://www.ensembl.org/id/"],    # ENSG00000139618
  #"massive"      => [],
  "pride"        => ["http://identifiers.org/pride.project/", "http://www.ebi.ac.uk/pride/archive/projects/"], # PXD000004
  "pubmed"       => ["http://identifiers.org/pubmed/", "http://www.ncbi.nlm.nih.gov/pubmed/"], # 16333295
  "taxonomy"     => ["http://identifiers.org/taxonomy/", "http://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?mode=Info&id="], # 9606
  "uniprot"      => ["http://identifiers.org/uniprot/", "http://www.uniprot.org/uniprot/"], # P62158

  "PomBase"      => ["http://identifiers.org/pombase/", "https://www.pombase.org/spombe/result/"], # SPCC962.03c assigned as Unknown
  "px"           => ["http://identifiers.org/px/", "http://proteomecentral.proteomexchange.org/dataset/"] # RPXD000650 assigned as Unknown
}

dbs = {
  "ArrayExpress"          => ["http://www.omicsdi.org/dataset/arrayexpress-repository/", "https://www.ebi.ac.uk/arrayexpress/"],
  "EGA"                   => ["http://www.omicsdi.org/dataset/ega/", "https://www.ebi.ac.uk/ega/"],
  "ExpressionAtlas"       => ["http://www.omicsdi.org/dataset/atlas-experiments/", "https://www.ebi.ac.uk/gxa/"],
  "GNPS"                  => ["http://www.omicsdi.org/dataset/gnps/", "https://gnps.ucsd.edu/"],
  "GPMDB"                 => ["http://www.omicsdi.org/dataset/gpmdb/", "http://gpmdb.thegpm.org/"],
  "Massive"               => ["http://www.omicsdi.org/dataset/massive/", "https://massive.ucsd.edu/"],
  "MetaboLights"          => ["http://www.omicsdi.org/dataset/metabolights_dataset/", "http://www.ebi.ac.uk/metabolights/"],
  "MetabolomeExpress"     => ["http://www.omicsdi.org/dataset/metabolome_express/", "https://www.metabolome-express.org/"],
  "MetabolomicsWorkbench" => ["http://www.omicsdi.org/dataset/metabolomics_workbench/", "http://www.metabolomicsworkbench.org/"],
  "PeptideAtlas"          => ["http://www.omicsdi.org/dataset/peptide_atlas/", "http://www.peptideatlas.org/"],
  "pride"                 => ["http://www.omicsdi.org/dataset/pride/", "http://www.ebi.ac.uk/pride/archive/"]
}


#########################################################
#  define PREFIX
#########################################################
rdf  = RDF::Vocabulary.new("http://www.w3.org/1999/02/22-rdf-syntax-ns#")
rdfs = RDF::Vocabulary.new("http://www.w3.org/2000/01/rdf-schema#")
dc   = RDF::Vocabulary.new("http://purl.org/dc/elements/1.1/")
dct  = RDF::Vocabulary.new("http://purl.org/dc/terms/")
skos = RDF::Vocabulary.new("http://www.w3.org/2004/02/skos/core#")
pav  = RDF::Vocabulary.new("http://purl.org/pav/")
sio  = RDF::Vocabulary.new("http://semanticscience.org/resource/")
odio = RDF::Vocabulary.new("https://raw.githubusercontent.com/OmicsDI-RDF/RDF/master/odio.owl#")


file = ARGV[0]

# sample files
#file = "../sample/arrayexpress/ARRAY_EXPRESS_EBE_1.xml"
#file = "../sample/ega/EGA_EBEYE_1.xml"
#file = "../sample/expression-atlas/EXPRESSION_ATLAS_EBE_1.xml"
#file = "../sample/gnps/GNPS_EBEYE_1.xml"
##file = "../sample/gpmdb/GPMDB_EBE_1.xml"
#file = "../sample/massive/MASSIVE_EBEYE_1.xml"
##file = "../sample/metabolights/METABOLIGHTS_EBEYE_1.xml"
#file = "../sample/metabolome-express/MEXPRESS_EBEYE_1.xml"
#file = "../sample/mw/MW_EBEYE_1.xml"
##file = "../sample/atlas/PeptideAtlas_EBEYE_1.xml"
#file = "../sample/pride/PRIDE_EBEYE_14.xml"
file = "/Volumes/orenostorage2/omicsDIrdf/curated-files/atlas/PeptideAtlas_EBEYE_3.xml"


f    = File.open(file)
doc  = REXML::Document.new(f)
g    = Graph.new

# database information
db    = doc.elements['/database/name'].text
dburi = RDF::URI(dbs[db][1])

g << [dburi, RDF.type, RDF::URI("http://semanticscience.org/resource/SIO_000750")]
g << [dburi, rdfs.label, db]
g << [dburi, dct.description, doc.elements['/database/description'].text]    if doc.elements['/database/description'] && doc.elements['/database/description'].text
g << [dburi, pav.version, doc.elements['/database/release'].text]           if doc.elements['/database/release']
g << [dburi, dct.available, doc.elements['/database/release_date'].text]

#=begin
doc.elements.each("database/entries/entry") do |entry|
  id      = entry.attributes['id']
  subject = RDF::URI("#{dbs[db][0]}#{id}")
  
  #base elements
  g << [subject, RDF.type, RDF::URI("https://raw.githubusercontent.com/OmicsDI-RDF/RDF/master/odio.owl##{db.sub(/^p/, "P")}Entry")]
  g << [subject, dct.identifier, id]
  g << [subject, dct.title, entry.elements['name'].text]
  g << [subject, rdfs.label, entry.elements['name'].text]
  g << [subject, dct.description, entry.elements['description'].text] if entry.elements['description'] && entry.elements['description'].text
  g << [subject, odio.authors, entry.elements['authors'].text]        if entry.elements['authors']    # only in Metabplights
  g << [subject, odio.keywords, entry.elements['keywords'].text]      if entry.elements['keywords']
  
  #dates
  entry.elements.each('dates/date') do |date|
    dateType = RDF::Node.new
    g << [subject, dc.date, dateType]
    g << [dateType, RDF.type, RDF::URI(dateTypes[date.attributes['type']])]
    g << [dateType, dct.date, RDF::Literal::Date.new(date.attributes['value'])] # dct:date has Range::Letral, dc:date doesnt have range
    
    #represent dates using dcterms
    if date.attributes['type'] == "creation"
      g << [subject, dct.created, RDF::Literal::Date.new(date.attributes['value'])]
    elsif date.attributes['type'] == "submission"
      g << [subject, dct.dateSubmitted, RDF::Literal::Date.new(date.attributes['value'])]
    elsif date.attributes['type'] == "publication" || date.attributes['type'] == "output" || date.attributes['type'] == "export"
      g << [subject, dct.issued, RDF::Literal::Date.new(date.attributes['value'])]
    elsif date.attributes['type'] == "last_modification" || date.attributes['type'] == "updated"
      g << [subject, dct.modified, RDF::Literal::Date.new(date.attributes['value'])]
    end
  end
  
  #cross_references
  entry.elements.each('cross_references/ref') do |ref|
    refType = RDF::Node.new
    g << [subject, odio.crossReference, refType]
    g << [refType, RDF.type, odio.Ref]

    rid = ref.attributes['dbkey']
    
    dbname = ref.attributes['dbname']
    if dbname == "Unknown"
      if dbname =~ /^RP/
        dbname = "px"
      elsif dbname =~ /^SP/
        dbname = "PomBase"
      end
    end
    
    p id
    dbNames[dbname].each do |url|
      g << [refType, skos.exactMatch, RDF::URI("#{url}#{rid}")] if url
    end
  end
  
  #additional fields
  entry.elements.each('additional_fields/field') do |field|
    g << [subject, RDF::URI("https://raw.githubusercontent.com/OmicsDI-RDF/RDF/master/odio.owl##{field.attributes['name']}"), field.text] if field.text
  end
end
#=end

#=begin
puts g.dump(:ttl, prefixes:{
  rdf:  "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
  rdfs: "http://www.w3.org/2000/01/rdf-schema#",
  dc:   "http://purl.org/dc/elements/1.1/",
  dct:  "http://purl.org/dc/terms/",
  skos: "http://www.w3.org/2004/02/skos/core#",
  pav:  "http://purl.org/pav/",
  sio:    "http://semanticscience.org/resource/",
  odio: "https://raw.githubusercontent.com/OmicsDI-RDF/RDF/master/odio.owl#"
})
#=end