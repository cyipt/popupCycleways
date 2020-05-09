Methods to prioritise pop-up active transport infrastructure
================
Robin Lovelace

# RESEARCH QUESTIONS AND HYPOTHESIS

The Covid-19 pandemic has transformed all sectors of the economy, not
least transport. [Demand for long distance trips has
plummetted](https://osf.io/preprints/socarxiv/v3g5d/) and [airline
companies have gone bust](https://arxiv.org/abs/2004.08460) (Iacus et
al. 2020; Jittrapirom and Tanaksaranond 2020). Yet short distance travel
patterns have also changed greatly and there has been an uptick in
cycling in some places (Harrabin 2020). There are two main explanations
for increased active transport during pandemic-related physical
distancing measures: 1) with fewer opportunities to exercise, more
people are taking to walking, running and cycling in their local area
for mental and physical health; and 2) public transport options have
been greatly reduced due to cuts in services and fear of being infected
while in enclosed spaces, meaning that walking and particularly cycling
may be the only way that workers can reach key destinations such as
hospitals. The second reason is particularly important given that many
‘key workers’ are low paid, with limited access to private
automobiles. From a physical activity perspective this change is
welcome: obesity is a powerful predictor of all-cause mortality,
including from Covid-19 (Docherty et al. 2020). From a physical
distancing perspective, increased levels of walking and cycling, the
shift creates pressure on governments to ensure sufficient ‘space for
social distancing’, while enabling increased active mobility for health
and travel to key workplaces.
<!-- particularly in densly populated urban areas where pavements and cycleways may be narrow,  -->

Local and national governments worldwide are still working out how best
to respond to these changes and many options are available to ensure
that citizens can benefit from outdoor activity while minimizing health
risks, ranging from the provision of hand sanitisers to opening-up
spaces such as parking lots and golf courses (Freeman and Eykelbosh
2020). Many local governments have responded by implementing ‘pop-up’
active transport infrastructure. The Scottish government, for example
has provided emergency funding “to keep key workers moving” by
“reallocating road space to better enable this shift and make it safer
for people who choose to walk, cycle or wheel for essential trips or for
exercise” (Transport Scotland 2020). A wide range of interventions is
possible, ranging from simple signing to the construction of new paths,
but the majority of pop-up activity can be classified into three broad
categories:

1.  ‘filtered permeability’ interventions to prevent through traffic,
    with interventions as part of Salford’s [‘Liveable Streets’
    project](https://salfordliveablestreets.commonplace.is/) being a
    prominent example (Salford City Council 2020)
    <!-- (see [here](https://twitter.com/CatrionaSwanson/status/1258322956595453952) for a photo illustrating this type of intervention) -->
2.  banning cars and to pedestrianise streets, greatly increasing the
    width of walkable space, New York’s ‘Open Streets’ initiative being
    a prominent example (Litman 2020), and
3.  the reallocation of one or more lanes of traffic to create pop-up
    cycleways, typically along arterial routes, with lanes reallocated
    using traffic cones in Auckland providing an early example
    (<span class="citeproc-not-found" data-reference-id="orsman_covid_2020">**???**</span>).

The focus of this article is on the third category. In it we aim to
answer the following research question:

> How can automated data analysis and interactive visualisation methods
> help prioritise the reallocation of road space for pop-up active
> transport infrastructure?

Because of the recent, localised and often ad-hoc nature of pop-up
infrastructure, it is difficult to make, let alone test, hypotheses
related to the research question. Our broad hypothesis is that digital
tools based on open data, such as the interactive map used to support
community-level responses to Covid-19 in Salford (Salford City Council
2020), illustrated in Figure 1, can lead to more effective use of
resources allocated to pop-up interventions.

![Screenshot from the website
[salfordliveablestreets.commonplace.is](https://salfordliveablestreets.commonplace.is/comments)
to support community and local government level responses to the
Covid-19 pandemic, including the prioritisation of pop-up active
transport
infrastructure.](https://user-images.githubusercontent.com/1825120/81451234-ed82d200-917b-11ea-977d-fff1665378c5.png)

<!-- With the rush to act, there is a great need for evidence of *where* new interventions should be prioritised. As with the medical science, research is needed now. Methods developed to identify locations of high walking and cycling potential can help ensure that the ‘pop-up’ infrastructure that goes in now is effective, safe, and placed where it is most needed. -->

# METHODS AND DATA

Three main datasets were used for the project:

  - Estimates of cycling potential to work at the street segment level
    from the UK Department for Transport funded Propensity to Cycle Tool
    (PCT) project (Goodman et al. 2019; Lovelace et al. 2017; Lovelace
    and Hama 2019)
  - Data derived from OpenStreetMap, with a number of new variables
    added to support cycling infrastructure planning (see www.cyipt.bike
    for an overivew)
  - A list hospital locations from the UK’s National Health Service
    website
    [www.nhs.uk](https://www.nhs.uk/about-us/nhs-website-datasets/)
    <!-- - Data on the location of road traffic casualties from -->

Datasets from the PCT and CyIPT project were combined into a single
file, key variables from which are shown in Table 1. A map showing the
spatial distribution of hospitals in the case study city of Leeds, which
is used for demonstrating the methods in the next section, is shown in
Figure <a href="#fig:hospitals">1</a>.

Table 1: Summary of the main road segment dataset for Leeds

<div class="figure">

<img src="article_files/figure-gfm/hospitals-1.png" alt="Overview map of input data, showing the main highway types and location of hospitals in Leeds"  />

<p class="caption">

Figure 1: Overview map of input data, showing the main highway types and
location of hospitals in Leeds

</p>

</div>

## Geographic subsetting

The region of analysis may seem like a basic consideration and for some
cities it is. However, there are various reasons why simply analysing
and plotting all possible transport network segments within the city or
regional boundaries may not be a good idea, as shown in Figure
<a href="#fig:geographic-subsetting"><strong>??</strong></a>.

## Levels of analysis and grouping

An important distinction when developing methods for automated analysis
of transport networks is the level of analysis.

![](article_files/figure-gfm/levels-1.png)<!-- -->

## Scenario development

# FINDINGS

We found that…

<!-- Guidance from https://transportfindings.org/for-authors -->

<!-- Transport Findings welcomes research findings in the broad field of transport. Articles must either pose a New Question,  present a New Method, employ New Data (including New Contexts or Locations),  discover a New Finding (i.e. it can almost exactly replicate a previous study and find something different), or some combination of the above. -->

<!-- Scope -->

<!-- You may find yourself asking if your paper is within the scope of Transport Findings. -->

<!--     Is there a hypothesis somehow related to transport? -->

<!--     Is there a (scientifically valid, replicable) methodology? -->

<!--     Is there a finding? -->

<!-- If you can answer yes to these questions, it is within scope. -->

<!-- Article Types -->

<!--     Findings - where the object of study is nature -->

<!--     Syntheses - where the object of study is the literature -->

<!--     Cases - where the objects of study are particular sites or projects, and methods may be more qualitative -->

<!-- Sections -->

<!-- All articles shall have 3 sections, and only 3 sections, titled as follows: -->

<!--     RESEARCH QUESTION[S] AND HYPOTHESIS[ES] -->

<!--     METHODS AND DATA -->

<!--     FINDINGS -->

<!-- There shall be no introduction, “road-map paragraph,” literature review, conclusions, speculations, or  policy implications beyond what is included above. Focus on what you found, not why you found it. -->

<!-- Submissions -->

<!-- The manuscript submission must include the following: -->

<!-- TITLE -->

<!-- AUTHORS (NAME, AFFILIATION, CONTACT) -->

<!-- ABSTRACT -->

<!-- KEYWORDS -->

<!-- ARTICLE (Sections 1, 2, 3) -->

<!-- ACKNOWLEDGMENTS -->

<!-- REFERENCES -->

<!-- Manuscript submissions may include SUPPLEMENTAL INFORMATION in separate files that do not count against article length. This information should not be essential for the general understanding of the manuscript. -->

<!-- Style -->

<!-- Focus and Parsimony -->

<!-- Papers should be focused and to the point, and not begin with trite observations like “Congestion is a problem the world over.” Usually you can delete your opening paragraph if it begins like that, and the reader is no worse off. As Strunk and White say: “Omit Needless Words”. The Abstract should not say the same thing as the Introduction. -->

<!-- Transparency and Replicability -->

<!-- A minimum standard for a good paper is transparency and replicability: Can the reader understand what you did, and repeat it, and get the same answer? -->

<!-- Mathematical Conventions -->

<!-- Each variable shall have one, and only one, definition per document. -->

<!-- Each defined term in the document shall be represented by one and only one variable. -->

<!-- Lowercase and uppercase versions of the same letter should be logically related. For instance, use lowercase letters to define the PDF (probability distribution function) or individual instance, and uppercase letters the CDF (cumulative distribution function) or population, so when you sum:  i=1 to I, k=1 to K, etc. -->

<!-- All variables shall be a single letter or symbol. Double or triple letter variables can be confused with multiplication. If you have more than 52 symbols in your paper (26 letters for both lower and upper case), consider (a) there are too many, and (b) using Greek or Hebrew characters. -->

<!-- Use subscripts liberally to differentiate things that, for instance, are of a class but measured differently, or computed with different assumptions. -->

<!-- All equations shall have all of their variables defined. -->

<div id="refs" class="references hanging-indent">

<div id="ref-docherty_features_2020">

Docherty, Annemarie B., Ewen M. Harrison, Christopher A. Green, Hayley
E. Hardwick, Riinu Pius, Lisa Norman, Karl A. Holden, et al. 2020.
“Features of 16,749 Hospitalised UK Patients with COVID-19 Using the
ISARIC WHO Clinical Characterisation Protocol.” *medRxiv*, April,
2020.04.23.20076042. <https://doi.org/10.1101/2020.04.23.20076042>.

</div>

<div id="ref-freeman_covid19_2020">

Freeman, Shirra, and Angela Eykelbosh. 2020. “COVID-19 and Outdoor
Safety: Considerations for Use of Outdoor Recreational Spaces.” BC
Centre for Disease Control.

</div>

<div id="ref-goodman_scenarios_2019">

Goodman, Anna, Ilan Fridman Rojas, James Woodcock, Rachel Aldred,
Nikolai Berkoff, Malcolm Morgan, Ali Abbas, and Robin Lovelace. 2019.
“Scenarios of Cycling to School in England, and Associated Health and
Carbon Impacts: Application of the ‘Propensity to Cycle Tool’.” *Journal
of Transport & Health* 12 (March): 263–78.
<https://doi.org/10.1016/j.jth.2019.01.008>.

</div>

<div id="ref-harrabin_boom_2020">

Harrabin, Roger. 2020. “Boom Time for Bikes as Virus Changes
Lifestyles.” *BBC News*, May.

</div>

<div id="ref-iacus_estimating_2020">

Iacus, Stefano Maria, Fabrizio Natale, Carlos Satamaria, Spyridon
Spyratos, and Michele Vespe. 2020. “Estimating and Projecting Air
Passenger Traffic During the COVID-19 Coronavirus Outbreak and Its
Socio-Economic Impact.” *arXiv:2004.08460 \[Physics, Stat\]*, April.
<http://arxiv.org/abs/2004.08460>.

</div>

<div id="ref-jittrapirom_exploratory_2020">

Jittrapirom, Peraphan, and Garavig Tanaksaranond. 2020. “An Exploratory
Survey on the Perceived Risk of COVID-19 and Travelling.” Preprint.
SocArXiv. <https://doi.org/10.31235/osf.io/v3g5d>.

</div>

<div id="ref-litman_pandemicresilient_2020">

Litman, Todd. 2020. “Pandemic-Resilient Community Planning.” Victoria
Transport Policy Institute.

</div>

<div id="ref-lovelace_propensity_2017">

Lovelace, Robin, Anna Goodman, Rachel Aldred, Nikolai Berkoff, Ali
Abbas, and James Woodcock. 2017. “The Propensity to Cycle Tool: An Open
Source Online System for Sustainable Transport Planning.” *Journal of
Transport and Land Use* 10 (1). <https://doi.org/10.5198/jtlu.2016.862>.

</div>

<div id="ref-R-pct">

Lovelace, Robin, and Layik Hama. 2019. *Pct: Propensity to Cycle Tool*.

</div>

<div id="ref-salfordcitycouncil_salford_2020">

Salford City Council. 2020. “Salford Liveable Streets.”
https://salfordliveablestreets.commonplace.is.

</div>

<div id="ref-transportscotland_10_2020">

Transport Scotland. 2020. “10 Million to Support Pop-up Active Travel
Infrastructure.”
https://www.transport.gov.scot/news/10-million-to-support-pop-up-active-travel-infrastructure/.

</div>

</div>
