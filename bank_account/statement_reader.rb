# frozen_string_literal: true
require 'csv'
require 'date'
require 'ofx_reader'
require 'ofx'

class Category
  attr_reader :category_type

  def initialize(category_type:, bank_statement_prefix: nil)
    @category_type = category_type
    @bank_statement_prefix = bank_statement_prefix
  end

  def ==(o)
    o.class == self.class && o.state == state
  end
  alias_method :eql?, :==

  def hash
    state.hash
  end

  def state
    [@category_type, @bank_statement_prefix]
  end

  def to_s
    @category_type
  end

  def matches_statement_item?(statement_item)
    to_match = @bank_statement_prefix || @category_type
    description = statement_item.description.downcase
    if to_match.is_a?(Array)
      to_match.any? { |t| description.include?(t.downcase) }
    else
      description.include?(to_match.downcase)
    end
  end
end

class NamedCategory < Category
  attr_reader :name
  def initialize(category_type:, name:, bank_statement_prefix: nil)
    super(category_type: category_type, bank_statement_prefix: bank_statement_prefix || name)
    @name = name
  end

  def to_s
    "#{@category_type}: #{@name}"
  end
end

class VortexStaff < NamedCategory
  def initialize(name:, bank_statement_prefix: nil)
    super(category_type: "Personnel", name: name, bank_statement_prefix: bank_statement_prefix)
  end

end

class Musicians < NamedCategory
  def initialize(name:, bank_statement_prefix: nil)
    super(category_type: "Musicians", name: name, bank_statement_prefix: bank_statement_prefix)
  end
end

class Members < NamedCategory
  def initialize(name:, bank_statement_prefix: nil)
    super(category_type: "Members", name: name, bank_statement_prefix: bank_statement_prefix)
  end
end

class UnknownNames < NamedCategory
  def initialize(name:, bank_statement_prefix: nil)
    super(category_type: "Unknown names", name: name, bank_statement_prefix: bank_statement_prefix)
  end
end

class Company < NamedCategory
  attr_reader :company_area
  def initialize(name:, bank_statement_prefix: nil, company_area: nil)
    super(category_type: "Company", name: name, bank_statement_prefix: bank_statement_prefix)
    @company_area = company_area
  end
end


class CashWithdrawal < Category
  def initialize
    super(category_type:"Cash Withdrawal", bank_statement_prefix: ["CASH HALIFAX", "CASH NOTEMAC"])
  end
end

class StripePayments < Category
  def initialize
    super(category_type:"Stripe Payments")
  end
end

class Unrecognised < Category
  def initialize
    super(category_type: "Unrecognised")
  end
end

class BarPurchases < NamedCategory
  attr_reader :name
  def initialize(name:, bank_statement_prefix: nil)
    super(name: name, category_type: "Bar Purchases", bank_statement_prefix: bank_statement_prefix)
  end
end


class NonSterlingTransactionFee < Category
  def initialize
    super(category_type: "Non-Sterling Transaction Fee", bank_statement_prefix: "Non-Sterling Transaction Fee")
  end
end

class InternetTransfer < Category
  def initialize
    super(category_type: "Internet Transfer", bank_statement_prefix: "400217 61414380 INTERNET TRANSFER")
  end
end


class LoanRepayment < Category
  def initialize
    super(category_type: "Loan Repayment", bank_statement_prefix: "HSBC PLC LOANS")
  end
end


class JazzInLondon < Category
  def initialize
    super(category_type: "Jazz in London", bank_statement_prefix: "JAZZ IN LONDON")
  end
end


class Paypal < Category
  def initialize
    super(category_type: "Paypal")
  end
end

class StudioUpstairs < Category
  def initialize
    super(category_type: "Studio Upstairs")
  end
end


class PasReCps < Category
  def initialize
    super(category_type: "PAS RE CPS")
  end
end

class HMRCVat < Category
  def initialize
    super(category_type: "HMRC VAT")
  end
end

class BankCharges < Category
  def initialize
    super(category_type: "Bank Charges", bank_statement_prefix: "TOTAL CHARGES TO")
  end
end


class VortexRBD < Category
  def initialize
    super(category_type: "Vortex RBD")
  end

  def matches_statement_item?(statement_item)
    description = statement_item.description.downcase
    (description.include?("vortex") || description.include?("van gelder")) && description.include?("rbd")
  end
end

class CosPayment < Category
  def initialize
    super(category_type: "COS PAYMENT", bank_statement_prefix: "COS UK")
  end
end

class Rehearsal < Category
  def initialize
    super(category_type: "Rehearsal", bank_statement_prefix: ["REHEARSAL", "daytime hire", "recording", "waterhouse"])
  end
end

class Membership < Category
  def initialize
    super(category_type: "Membership", bank_statement_prefix: ["Member"])
  end
end

class ArtsCouncilGrant < Category
  def initialize
    super(category_type: "Arts Council Grant")
  end
end
class UKVIUK < Category
  def initialize
    super(category_type: "UKVIUK")
  end
end

COMPANIES = [
  Company.new(name: "Acme Catering", company_area: "Catering"),
  Company.new(name: "Close Marsh Comm", bank_statement_prefix: "CLOSE - MARSH", company_area: "Insurance"),
  Company.new(name: "Denise", bank_statement_prefix: "Denise Williams", company_area: "Security"),
  Company.new(name: "EDF", bank_statement_prefix: "EDF ENERGY", company_area: "Power"),
  Company.new(name: "HCD", company_area: "Landlord"),
  Company.new(name: "Kashflow", bank_statement_prefix: "WWW.KASHFLOW.COM", company_area: "Accounting"),
  Company.new(name: "Locksmiths", bank_statement_prefix: "G K LOCKSMITHS", company_area: "Locksmiths"),
  Company.new(name: "London Borough of Hackney", bank_statement_prefix: "LB Hackney", company_area: "Council"),
  Company.new(name: "Music Venue Trust", company_area: "Charity"),
  Company.new(name: "Music Venues Alliance", bank_statement_prefix: "MUSIC VENUES ALL", company_area: "Charity"),
  Company.new(name: "Oblong", company_area: "Website"),
  Company.new(name: "Piano Tuner", bank_statement_prefix: "B SHARP PIANOS", company_area: "Piano Tuner"),
  Company.new(name: "Poolfresh", bank_statement_prefix: "POOLFRESH LTD", company_area: "Cleaning"),
  Company.new(name: "Premier Cars", bank_statement_prefix: ["Premier Cars", "Premiercars"], company_area: "Taxi"),
  Company.new(name: "Rentokil", company_area: "Pest Control"),
  Company.new(name: "Salmonstone", company_area: "Building?"),
  Company.new(name: "Ticketweb", bank_statement_prefix: ["Ticketweb", "TW Client"], company_area: "Ticketing"),
  Company.new(name: "Unknown Works", bank_statement_prefix: "Unknown Works Ltd"),
  Company.new(name: "Vortex Interiors", company_area: "Building"),
  Company.new(name: "airtable", company_area: "database"),
  Company.new(name: "Vivid Lifts", company_area: "lifts"),
  Company.new(name: "Ticketco", company_area: "Ticketing"),
  Company.new(name: "ADT New Alarm", bank_statement_prefix: ["ADT "], company_area: "Alarm"),
  Company.new(name: "Mailchimp", company_area: "email"),
  Company.new(name: "Laurence Dixon", company_area: "bass"),
  Company.new(name: "London Eye Construction", bank_statement_prefix: "London Eye", company_area: "building"),
  Company.new(name: "Sango Air Con", company_area: "air con"),
  Company.new(name: "HY TEK ELECTRONICS", company_area: "electronics"),
  Company.new(name: "SP INSPYER LIGHT", company_area: "lighting"),
  Company.new(name: "Toilet Hire", company_area: "toilets"),
  Company.new(name: "Direct 365", company_area: "Facility magement"),
  Company.new(name: "Vistaprint", company_area: "Printing"),
]

STAFF = [
  VortexStaff.new(name: "Kim Macari"),
  VortexStaff.new(name: "Daniel Garel"),
  VortexStaff.new(name: "Pauline Le Divenache", bank_statement_prefix: "PAULINE LE DIV"),
  VortexStaff.new(name: "Lasse Lottgen"),
  VortexStaff.new(name: "Kathianne Hingwan", bank_statement_prefix: ["K HINGWAN", "HINGWAN K C"]),

  VortexStaff.new(name: "Milo McGuire"),
  VortexStaff.new(name: "Joe Mashiter"),
  VortexStaff.new(name: "Thomas Pew"),
  VortexStaff.new(name: "Jorge Martinez"),
  VortexStaff.new(name: "Alex McGuire"),
  VortexStaff.new(name: "Chris Penty"),
  VortexStaff.new(name: "Bella Cooper"),
  VortexStaff.new(name: "Jeremy Sliwerski"),
  VortexStaff.new(name: "Kinga Ilyes"),
  VortexStaff.new(name: "Colin Daly"),
  VortexStaff.new(name: "Oliver Weindling"),
  VortexStaff.new(name: "Laurie Evans"),
]

MUSICIANS = [
  Musicians.new(name: "Alex Hitchcock"), Musicians.new(name: "A C Kemp"), Musicians.new(name: "Barry Green"), Musicians.new(name: "Bill Marrows"), Musicians.new(name: "Bruno Heinen"), Musicians.new(name: "Calum Gourlay"),
  Musicians.new(name: "Chris Batchelor"), Musicians.new(name: "Chris Sansom", bank_statement_prefix: "C Sansom PERFECT"), Musicians.new(name: "Georgia Mancio"), Musicians.new(name: "Hans Koller"), Musicians.new(name: "Harrison Smith"),
  Musicians.new(name: "Helena Kay"), Musicians.new(name: "Henry Lowther"), Musicians.new(name: "Jack Davey"), Musicians.new(name: "James Allsopp", bank_statement_prefix: "ALLSOPP J"), Musicians.new(name: "James Kitchman"),
  Musicians.new(name: "Jas Kayser"), Musicians.new(name: "John Etheridge"), Musicians.new(name: "Julian Seigel"), Musicians.new(name: "Liam Noble"), Musicians.new(name: "Maddy Coombs"),
  Musicians.new(name: "Mark Lockheart"), Musicians.new(name: "Marta Gornitzka"), Musicians.new(name: "Martin Speake"), Musicians.new(name: "Mopomoso"), Musicians.new(name: "Murphy O J"),
  Musicians.new(name: "Nick Costley-White", bank_statement_prefix: ["N Costley", "Nick Costley"]), Musicians.new(name: "Norma Winstone"), Musicians.new(name: "Ollie Brice", bank_statement_prefix: ["Ollie Brice", "Olie Brice"]), Musicians.new(name: "Olly Chalk", bank_statement_prefix: ["Chalk Oliver", "Olly Chalk"]), Musicians.new(name: "Orlando le Fleming"),
  Musicians.new(name: "Orphy Robinson"), Musicians.new(name: "Paul Clarvis"), Musicians.new(name: "Pete Wareham"), Musicians.new(name: "Rachel Cohen", bank_statement_prefix: ["Rachel Cohen", "Rachael Cohen"]), Musicians.new(name: "Rachel Musson"),
  Musicians.new(name: "Rick Simpson"), Musicians.new(name: "Riley Stone-Lonergon", bank_statement_prefix: "R STONE-LONER"), Musicians.new(name: "Robert Mitchell"), Musicians.new(name: "Samuel Glass"), Musicians.new(name: "Sam Jewison", bank_statement_prefix: "S Jewison"),
  Musicians.new(name: "Sean Gibbs"), Musicians.new(name: "Stan Sulzmann"), Musicians.new(name: "Stefan Ancora", bank_statement_prefix: ["Stefan Ancora", "Stefano Ancora"]), Musicians.new(name: "Steve Buckley"), Musicians.new(name: "Tom Ollendorff"),
  Musicians.new(name: "Tom Remon"), Musicians.new(name: "Toni Kofi"), Musicians.new(name: "Will Glaser"), Musicians.new(name: "Elliot Galvin"), Musicians.new(name: "Jean Toussaint"),
  Musicians.new(name: "Tom Syson"), Musicians.new(name: "Simon Purcell"), Musicians.new(name: "Sam Norris Vortex"), Musicians.new(name: "Paul Jolly"), Musicians.new(name: "Sheila Maurice"),
  Musicians.new(name: "James Allsopp"), Musicians.new(name: "ALICE LEGGETT"), Musicians.new(name: "David Miller"), Musicians.new(name: "Brigitte Beraha", bank_statement_prefix: ["BERAHAB", "Brigitte Beraha"]), Musicians.new(name: "Arisema Tekle"),
  Musicians.new(name: "Adam Teixeira"), Musicians.new(name: "Debora Monfregola"), Musicians.new(name: "Gina Boreham"), Musicians.new(name: "Thibaut Remy"), Musicians.new(name: "Chris Hyde-Harrison", bank_statement_prefix: ["Hyde-Harrison"]),
  Musicians.new(name: "Cleveland Watkiss"), Musicians.new(name: "Phelan Burgoyne"), Musicians.new(name: "J Hill"), Musicians.new(name: "Sue Aperghis"), Musicians.new(name: "Basil Hodge"),
  Musicians.new(name: "Joseph Henwood"), Musicians.new(name: "Alex Ward"), Musicians.new(name: "Viva Voce"), Musicians.new(name: "Felix Threadgill"), Musicians.new(name: "Corrie Dick"),
  Musicians.new(name: "Ella Hohnen"), Musicians.new(name: "Larry Bartley"), Musicians.new(name: "Kate Shortt"), Musicians.new(name: "Mike Guy"),
  Musicians.new(name: "Emma Rawicz", bank_statement_prefix: "Rawicz"),
  Musicians.new(name: "Alexandra Ridout"),
  Musicians.new(name: "Chris Dowding", bank_statement_prefix: ["Chris Dowding", "Dowding C"]),
  Musicians.new(name: "Binker Golding"), Musicians.new(name: "Rayner A"), Musicians.new(name: "Jefford G"),
  Musicians.new(name: "Caius Williams"), Musicians.new(name: "Imogen Churchill"), Musicians.new(name: "Joy Ellis"), Musicians.new(name: "Jason Yarde"), Musicians.new(name: "World Music Band"),
  Musicians.new(name: "Elaine Mitchener"), Musicians.new(name: "Derick Bolansoy"), Musicians.new(name: "Loz Speyer"), Musicians.new(name: "Sarah Gillespie"), Musicians.new(name: "Max Luthert"),
  Musicians.new(name: "Derick Bolansoy"), Musicians.new(name: "Nathaniel Facey"), Musicians.new(name: "Tomas Challenger"), Musicians.new(name: "Chris Williams"), Musicians.new(name: "David Austin"),
  Musicians.new(name: "Scott Stroman"), Musicians.new(name: "Ben Somers"), Musicians.new(name: "Nicholas Malcolm"), Musicians.new(name: "Aliyah Qayum"), Musicians.new(name: "W Frankel"),
  Musicians.new(name: "Dee Byrne"), Musicians.new(name: "Nicholas Malcolm"), Musicians.new(name: "Jim Howard"), Musicians.new(name: "Christian Billard"), Musicians.new(name: "Harry Christelis"),
  Musicians.new(name: "Germana La Sorsa"), Musicians.new(name: "Tea Earle"), Musicians.new(name: "M Goodall"), Musicians.new(name: "Toby Medland"), Musicians.new(name: "Alina Bzhezhinska"),
  Musicians.new(name: "Tom Cawley"), Musicians.new(name: "Royal Academy of Music", bank_statement_prefix: "Royal Academy of M"), Musicians.new(name: "Maddalena Ghezzi"), Musicians.new(name: "Charlie Nash"), Musicians.new(name: "Xhosa Cole"),
  Musicians.new(name: "Hugh Pascall"), Musicians.new(name: "Lily Lyons"), Musicians.new(name: "Kit Downes"), Musicians.new(name: "Heidi Vogel"), Musicians.new(name: "Filomena Campus"),
  Musicians.new(name: "Huw Warren"), Musicians.new(name: "Maria Argiro"), Musicians.new(name: "Arun Ghosh"), Musicians.new(name: "Liran Donin"), Musicians.new(name: "Emma Johnson"),
  Musicians.new(name: "Nat Catchpole"), Musicians.new(name: "Fini Bearman"), Musicians.new(name: "Sultan Stevenson"), Musicians.new(name: "Ashley Paul"), Musicians.new(name: "Louise Dodds"),
  Musicians.new(name: "Sylvia Cohen"), Musicians.new(name: "Miles Mindlin"), Musicians.new(name: "Twm Dylan"), Musicians.new(name: "Rob Luft"), Musicians.new(name: "Jessica Bullen"),
  Musicians.new(name: "Tori Freestone"), Musicians.new(name: "Jamie Walton"), Musicians.new(name: "M Carter"),
  Musicians.new(name: "Miguel Gorodi"), Musicians.new(name: "Alistair Martin"), Musicians.new(name: "David Smith"),
  Musicians.new(name: "Maria Harper"), Musicians.new(name: "Veryan Weston"), Musicians.new(name: "Tom Ward"), Musicians.new(name: "Alex Munk"),
  Musicians.new(name: "Laura Jurd"), Musicians.new(name: "Adam Osmianski"), Musicians.new(name: "MOJO"), Musicians.new(name: "Ed Jones"),
  Musicians.new(name: "Huw V Williams"), Musicians.new(name: "George Crowley"), Musicians.new(name: "Jade Evans"), Musicians.new(name: "Jon Onabowu"),
  Musicians.new(name: "Sam Hogarth"), Musicians.new(name: "Radhika de Saram"), Musicians.new(name: "Quentin Collins"), Musicians.new(name: "Anita Wardell"),
  Musicians.new(name: "Karim Saber"), Musicians.new(name: "Luna Cohen"), Musicians.new(name: "Sean Payne"), Musicians.new(name: "JMI"),
  Musicians.new(name: "Asha Parkinson"), Musicians.new(name: "Graham Costello"), Musicians.new(name: "RC Bolansoy"),
  Musicians.new(name: "P G Bradshaw FTS"), Musicians.new(name: "Keyo Yendii"), Musicians.new(name: "Aurelie Freoua"),
  Musicians.new(name: "Eddie Parker"), Musicians.new(name: "Matt Anderson"), Musicians.new(name: "Noah Stoneman"), Musicians.new(name: "Guido Spannocchi"),
  Musicians.new(name: "Ruth Goller"), Musicians.new(name: "Ayo Vincent"), Musicians.new(name: "Tara Minton"), Musicians.new(name: "Andrea Di Biase"),
  Musicians.new(name: "Alex Bonney"),
  Musicians.new(name: "Josephine Davies", bank_statement_prefix: ["Josephine Davies", "Davies JL"]),
  Musicians.new(name: "Maria Rehakova"), Musicians.new(name: "Christine Tobin"),
  Musicians.new(name: "Mark Kavuma"), Musicians.new(name: "R Ellis Beckles"), Musicians.new(name: "Matthew Herd"), Musicians.new(name: "Chris Stylianidis"),
  Musicians.new(name: "Leon Thomas"), Musicians.new(name: "Mark Holub"), Musicians.new(name: "Ed Puddick"), Musicians.new(name: "Will Vinson"),
  Musicians.new(name: "Seb Rochford"), Musicians.new(name: "Oren Marshall"), Musicians.new(name: "Tony Dudley Evans"), Musicians.new(name: "Max Tomlinson"),
  Musicians.new(name: "Paul Howard", bank_statement_prefix: ["HOWARD PS"]),
  Musicians.new(name: "Eirik Svela"),
  Musicians.new(name: "Hannes Reipler"),
  Musicians.new(name: "Paul Ryan"),
  Musicians.new(name: "Trish Clowes", bank_statement_prefix: ["TRISH CLOWES", "TRISHCLOWES"]),
]


DALSTON_LOCAL = BarPurchases.new(name: "Dalston Local", bank_statement_prefix: "DALSTON LOCAL")
BAR_PURCHASES = [
  BarPurchases.new(name: "Aldi", bank_statement_prefix: "Aldi "),
  BarPurchases.new(name: "Allparts"),
  BarPurchases.new(name: "Amazon", bank_statement_prefix: "amazon"),
  BarPurchases.new(name: "Argos", bank_statement_prefix: "Argos Ltd"),
  BarPurchases.new(name: "Bar Snacks", bank_statement_prefix: "UK BAR SNACKS"),
  DALSTON_LOCAL,
  BarPurchases.new(name: "Dalston Stationers"),
  BarPurchases.new(name: "ELB", bank_statement_prefix: "EAST LONDON B"),
  BarPurchases.new(name: "Flint Wines", bank_statement_prefix: "FLINT WINES"),
  BarPurchases.new(name: "Food & Wine"),
  BarPurchases.new(name: "HUMBLE GRAPE"),
  BarPurchases.new(name: "Jewson London"),
  BarPurchases.new(name: "Leyland SDM"),
  BarPurchases.new(name: "Majestic Wine", bank_statement_prefix: "MAJESTIC WINE"),
  BarPurchases.new(name: "Nisbets", bank_statement_prefix: "WWW.NISBETS.COM"),
  BarPurchases.new(name: "Post Office"),
  BarPurchases.new(name: "Poundland"),
  BarPurchases.new(name: "Sainsburys"),
  BarPurchases.new(name: "WWW.GAK.CO.UK"),
  BarPurchases.new(name: "shopify"),
  BarPurchases.new(name: "home living"),
  BarPurchases.new(name: "waitrose"),
  BarPurchases.new(name: "east london liquor"),
]

MEMBERS = [
  Members.new(name: "Chinny", bank_statement_prefix: "CHINEKWU OPUTA"),
  Members.new(name: "Ahmad Marie"),
  Members.new(name: "M B DUNLOP"),
  Members.new(name: "WOODS CS"),
  Members.new(name: "KRAABEL"),
  Members.new(name: "SMETHURST D"),
]

UNKNOWN_NAMES = [
  UnknownNames.new(name: "M SHAW"),
  UnknownNames.new(name: "fergione"),
  UnknownNames.new(name: "wetransfer"),
  UnknownNames.new(name: "Movimientos"),
  UnknownNames.new(name: "Davies M"),
  UnknownNames.new(name: "Mitchell R P"),
  UnknownNames.new(name: "Smith T E"),
  UnknownNames.new(name: "Dusty Knuc"),
  UnknownNames.new(name: "PAK Cosmetic"),
  UnknownNames.new(name: "Chief Chops"),
  UnknownNames.new(name: "Eastmond"),
  UnknownNames.new(name: "Chaser Productions"),
  UnknownNames.new(name: "KLARNA"),
  UnknownNames.new(name: "KINGSLANDLOCKE"),
  UnknownNames.new(name: "Lawrence N T NOAH"),
  UnknownNames.new(name: "Another Timbre"),
  UnknownNames.new(name: "TLC DIRECT"),
  UnknownNames.new(name: "holub"),
  UnknownNames.new(name: "signmax"),
  UnknownNames.new(name: "holistic"),
  UnknownNames.new(name: "intothe void"),
  UnknownNames.new(name: "flying duck"),
  UnknownNames.new(name: "hootsuite"),
  UnknownNames.new(name: "charge renewal"),
  UnknownNames.new(name: "higham"),
  UnknownNames.new(name: "kemshell"),
  UnknownNames.new(name: "jazzpromotion"),
  UnknownNames.new(name: "ACE - RESTRICTED"),
  UnknownNames.new(name: "CK PARTNERSHIP"),
  UnknownNames.new(name: "Cheng Xie"),
  UnknownNames.new(name: "Copasetic"),
  UnknownNames.new(name: "DBMA LTD"),
  UnknownNames.new(name: "Get Hire Limited"),
  UnknownNames.new(name: "J & C Joel"),
  UnknownNames.new(name: "Jewish Music"),
  UnknownNames.new(name: "Laura Kazaroff"),
  UnknownNames.new(name: "Puck London"),
  UnknownNames.new(name: "Stripe Mushroom"),
  UnknownNames.new(name: "Studio Design"),
  UnknownNames.new(name: "Studio Upstairs"),
  UnknownNames.new(name: "Verschuuren"),
  UnknownNames.new(name: "Dafydd James"),
  UnknownNames.new(name: "H2 Catering"),
  UnknownNames.new(name: "Catering24"),
  UnknownNames.new(name: "Duke St"),
  UnknownNames.new(name: "Krystal"),
  UnknownNames.new(name: "Rossi"),
  UnknownNames.new(name: "Music Store"),
  UnknownNames.new(name: "Cubitt"),
  UnknownNames.new(name: "Manushi"),
  UnknownNames.new(name: "httpscanva"),
  UnknownNames.new(name: "advice confirms rbh29"),
  UnknownNames.new(name: "rio cinema"),
  UnknownNames.new(name: "unpredictable"),
  UnknownNames.new(name: "kopliku"),
  UnknownNames.new(name: "hughes rp"),
  UnknownNames.new(name: "rewopower"),
  UnknownNames.new(name: "GIK Europe"),
]

KNOWN_CATEGORIES = [
  ArtsCouncilGrant.new,
  BankCharges.new,
  CashWithdrawal.new,
  HMRCVat.new,
  InternetTransfer.new,
  JazzInLondon.new,
  LoanRepayment.new,
  NonSterlingTransactionFee.new,
  PasReCps.new,
  Paypal.new,
  StripePayments.new,
  VortexRBD.new,
  Rehearsal.new,
  UKVIUK.new,
  Membership.new,
  CosPayment.new
] + STAFF + MUSICIANS + BAR_PURCHASES + MEMBERS + UNKNOWN_NAMES + COMPANIES

UNRECOGNISED = Unrecognised.new

class StatementItem
  attr_reader :date, :description, :amount, :balance, :category

  def initialize(date:, type:, description:, amount:, balance:, category: nil)
    @date = date
    @type = type
    @description = description
    @amount = amount
    @balance = balance
    @category = category
  end

  def categorise
    def with_category(category)
      StatementItem.new(
        date: @date,
        type: @type,
        description: @description,
        amount: @amount,
        balance: @balance,
        category: category
      )
    end
    matching_category = KNOWN_CATEGORIES.find { |category| category.matches_statement_item?(self) }
    if matching_category
      with_category(matching_category)
    else
      with_category(UNRECOGNISED)
    end
  end

  def self.from_csv_file(file_path)
    File.readlines(file_path).drop(1).collect do |line|
      terms = line.split(',')
      raise "Unexpected number of terms in line #{line}" unless terms.length == 5
      StatementItem.new(
        date: Date.parse(terms[0]),
        type: terms[1],
        description: terms[2],
        amount: terms[3].to_f,
        balance: terms[4].to_f
      ).categorise
    end
  end

  def self.from_ofx_file(file_path)
    ofx = OFXReader.(file_path)
    puts("here")

  end

end

path = File.absolute_path(File.join("/Users", "alex", "vortex", "bank statements", "20230412_61414372.csv"))
StatementItem.from_ofx_file(path)
# path = File.absolute_path(File.join("/Users", "alex", "vortex", "bank statements", "RT_20230124_61414372.csv"))
# path = File.absolute_path(File.join("/Users", "alex", "vortex", "bank statements", "20230112_61414372.csv"))
# items = StatementItem.from_csv_file(path)
# items.select { |item| item.category == DALSTON_LOCAL}.sort_by { |item| item.date }.each do |item|
#   puts "#{item.date} #{item.description} #{item.amount}"
# end

# by_category = items.group_by { |item| item.category }
# keys = by_category.keys.sort_by { |k| k.to_s }
# keys.each do |k|
#   v = by_category[k]
#   sum = v.sum { |item| item.amount }
#   puts "#{k}: #{v.length}, #{sum}"
# end