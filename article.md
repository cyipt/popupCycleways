Methods to prioritise pop-up active transport infrastructure and their
application in a national cycleway prioritisation tool
================
Robin Lovelace, Joey Talbot, Malcolm Morgan, Martin-Lucas-Smith

# Abstract

<!-- This paper reports on methods developed to support the identification of pop-up active transport infrastructure. -->

In the context of reduced public transport capacity in the wake of the
COVID-19 pandemic, governments are scrambling to enable walking and
cycling while adhering to physical distancing guidelines. A range of
pop-up options exist, include road space reallocation, which represents
a ‘quick win’ for cities with ‘spare space’ along continuous road
sections that have high latent cycling potential. We developed methods
to condense the complexity of city networks down to the most promising
roads for road space reallocation schemes. The resulting Rapid Cycleway
Prioritisation Tool has been deployed for all local and regional
transport authorities in England to help prioritise emergency funds for
new cycleways nationwide. The approach could be used to support
investment in pop-up infrastructure in cities worldwide.

# RESEARCH QUESTIONS AND HYPOTHESIS

<!-- The COVID-19 pandemic has transformed all sectors of the economy, not least transport. -->

<!-- [Demand for long distance trips has plummetted](https://osf.io/preprints/socarxiv/v3g5d/) and [airline companies have gone bust](https://arxiv.org/abs/2004.08460) [@iacus_estimating_2020; @jittrapirom_exploratory_2020]. -->

Much attention has focused on the impacts of COVID-19 on long-distance
travel patterns (e.g. Iacus et al. 2020; Jittrapirom and Tanaksaranond
2020) but short distance travel patterns have also changed. There has
been a notable increase in cycling in some areas (Harrabin 2020) due to
the increased need for exercise close to home for mental and physical
health (Jim’enez-Pav’on, Carbonell-Baeza, and Lavie 2020) and a
reduction in public transport options (e.g. Tian et al. 2020). The
second reason is particularly important given that many ‘key workers’
are low paid, with limited access to private automobiles.

<!-- due to cuts in services and fear of being infected while in enclosed spaces, meaning that walking and particularly cycling may be the only way that workers can reach key destinations such as hospitals. -->

<!-- From a physical activity perspective this change is welcome: obesity is a powerful predictor of all-cause mortality, including from COVID-19 [@docherty_features_2020]. -->

<!-- From a physical distancing perspective, increased levels of walking and cycling, -->

<!-- the shift creates pressure on governments to ensure sufficient 'space for social distancing', while enabling increased active mobility for health and travel to key workplaces. -->

<!-- particularly in densly populated urban areas where pavements and cycleways may be narrow,  -->

Local and national governments are working out how best to respond. Many
options are available to ensure that citizens can benefit from outdoor
activity while minimising health risks, ranging from hand sanitiser
provision to the creation of extra active transport space (Freeman and
Eykelbosh 2020). Installation of ‘pop-up’ active transport
infrastructure has been endorsed and implemented in many places (Laker
2020). The Scottish government, for example, has provided £10 million
“to keep key workers moving” by “reallocating road space to better
enable this shift and make it safer for people who choose to walk, cycle
or wheel for essential trips or for exercise” (Transport Scotland 2020).
On 9<sup>th</sup> May 2020, the UK government announced a £250 million
package for pop-up active transport infrastructure (Reid 2020).
Significantly, alongside this funding comes updated [statutory
guidance](https://www.gov.uk/government/publications/reallocating-road-space-in-response-to-covid-19-statutory-guidance-for-local-authorities/traffic-management-act-2004-network-management-in-response-to-covid-19)
on pop-up infrastructure and safety. Evidence is needed to ensure that
such investment is spent effectively and where it is most needed.

Most pop-up active transport infrastructure can be classified into three
broad categories:

1.  Measures such as point closures or contraflow cycle lanes, which can
    be used to promote ‘filtered permeability’, a strategy in which
    street networks are redesigned so that routes for cyclists are
    faster and more direct than routes for drivers. An example of this
    is
    [shown](https://twitter.com/TowerHamletsNow/status/1257564043856019458)
    in \[Tower Hamlets\].
2.  Measures to close roads entirely to cars, either permanently or at
    certain times of day, as in New York’s ‘Open Streets’ scheme (Litman
    2020).
3.  Measures to reallocate space on wide roads to create new cycleways
    or to widen pavements (Orsman 2020).
    <!-- interventions to prevent through traffic, with interventions as part of Salford's ['Liveable Streets' project](https://salfordliveablestreets.commonplace.is/) being a prominent example  -->
    <!-- (see [here](https://twitter.com/CatrionaSwanson/status/1258322956595453952) for a photo illustrating this type of intervention) -->

The focus of this article is on the third category. The research
question is:

> How can automated data analysis and interactive visualisation methods
> help prioritise the reallocation of road space for pop-up active
> transport infrastructure?

Because of the recent, localised and often ad-hoc nature of pop-up
infrastructure, it is difficult to make, let alone test, hypotheses
related to the research question. Our broad hypothesis is that digital
tools based on open data, combined with crowdsourcing such as the
interactive map used to support community-level responses to COVID-19 in
Salford (Salford City Council 2020), illustrated in Figure 1, can lead
to more effective use of resources allocated to pop-up interventions.

<div class="figure">

<img src="figures/jpg/widenmypath.jpeg" alt="Screenshots from the websites widenmypath.com (top) which includes top cycle route recommendations generated using the methods outlined in this paper in an open web forum, and salfordliveablestreets.commonplace.is (bottom) to support local responses to the COVID-19 pandemic, including the prioritisation of pop-up active transport infrastructure." width="100%" /><img src="figures/jpg/saferstreets.jpeg" alt="Screenshots from the websites widenmypath.com (top) which includes top cycle route recommendations generated using the methods outlined in this paper in an open web forum, and salfordliveablestreets.commonplace.is (bottom) to support local responses to the COVID-19 pandemic, including the prioritisation of pop-up active transport infrastructure." width="100%" />

<p class="caption">

Figure 1: Screenshots from the websites widenmypath.com (top) which
includes top cycle route recommendations generated using the methods
outlined in this paper in an open web forum, and
salfordliveablestreets.commonplace.is (bottom) to support local
responses to the COVID-19 pandemic, including the prioritisation of
pop-up active transport infrastructure.

</p>

</div>

<!-- With the rush to act, there is a great need for evidence of *where* new interventions should be prioritised. As with the medical science, research is needed now. Methods developed to identify locations of high walking and cycling potential can help ensure that the 'pop-up' infrastructure that goes in now is effective, safe, and placed where it is most needed. -->

# METHODS AND DATA

Two key datasets were used for the project:

  - Estimates of cycling potential at the street segment level from the
    UK Department for Transport funded Propensity to Cycle Tool (PCT)
    project (Goodman et al. 2019; Lovelace et al. 2017)
  - Data derived from OpenStreetMap, with several new variables added to
    support cycling infrastructure planning (see www.cyipt.bike for an
    overview)
    <!-- - Data on the location of road traffic casualties from -->

Datasets from the PCT and CyIPT project were merged, resulting in
crucial variables summarised in Table 1. Cycling potential is defined as
the number of one-way journeys to work and to school, under a scenario
in which the government aim of doubling cycling levels is met. This does
not include other types of journey such as leisure and shopping.

Roads are classified by speed limit because this has been shown to be a
key factor associated with the incidence of severe injuries and
fatalities of cyclists (Chen and Shen 2016), with odds of cyclist injury
on 20 mph (32.2 kmph) roads in London found to be 21% lower than on 30
mph (48.3 kmph) roads (Aldred et al. 2018). Therefore the suitability of
roads for cycle infrastructure, the preferred degree of physical
segregation, or the necessity to reduce traffic speeds could all be
influenced by current speed limits.

<!-- Could say more about the case study city here if there is space -->

## Geographic subsetting

The region of analysis may seem like a basic consideration: most cities
have well-defined administrative zones. In Leeds and many other cities,
it makes sense to focus on the region directly surrounding the city
centre, in a kind of ‘geographical triage’ to omit from the analysis
pop-up options in the outskirts, focus valuable attention on the routes
that are most likely to serve the highest number of people, and ensure
that road sections outside administrative areas but close to key
destinations are included.

<!-- The parameter `city_centre_buffer_radius` with an initial value of 8 km (5 miles) to geographically subset potential routes. -->

<!-- This represents a distance that most people have the physical ability to cycle. -->

Figure <a href="#fig:gsub">2</a> shows three broad strategies for
geographic subsetting: based on administrative boundaries, distance from
the centre, and distance from the centre and key destinations. Major
hospitals are used to illustrate the third strategy, as many key workers
need to get to hospitals. Schools could also be used here as an example
of a key destination that may not fit well within administrative zones.
The latter case (Figure <a href="#fig:gsub">2</a>, right) shows that
administrative boundaries can exclude important roads. The definition of
‘city centres’ and ‘key destinations’ is straightforward in clearly
defined and well-understood city planning contexts. In contexts where
the method must be deployed nationwide, however the use of such
subsetting approaches was found to be problematic, so the Rapid Cycleway
Prioritisation Tool for England (v1) uses the first subsetting option,
but subsets by larger regional boundaries to encourage regional
collaboration on cycleway network design. <!-- could say more... -->

<div class="figure">

<img src="article_files/figure-gfm/gsub-1.png" alt="Illustration of geographic subsetting based on administrative boundaries (left), distance to a central point (middle) and distance to city centre or key destinations (right). Radii of 5 km, 8 km and 10 km are shown for reference (note that some roads within 10 km of the center are outside the regional boundary). Units of speed are in miles per hour (mph), with 20, 30 and 40 mph representing 32, 48 and 64 kilometers per hour respectively." width="100%" />

<p class="caption">

Figure 2: Illustration of geographic subsetting based on administrative
boundaries (left), distance to a central point (middle) and distance to
city centre or key destinations (right). Radii of 5 km, 8 km and 10 km
are shown for reference (note that some roads within 10 km of the center
are outside the regional boundary). Units of speed are in miles per hour
(mph), with 20, 30 and 40 mph representing 32, 48 and 64 kilometers per
hour respectively.

</p>

</div>

## Road attributes

Pop-up cycleways can be placed either on the side of wide roads (as is
the case on [South Road,
Lancaster](https://www.lancasterguardian.co.uk/news/uk-news/mixed-reactions-new-lancaster-pop-cycle-lanes-busy-city-centre-road-2875909))
or in an entire lane that has been closed to motor traffic (as is the
case on [Park
Lane](https://metro.co.uk/2020/05/14/road-turns-giant-cycle-lane-make-social-distancing-easier-12703847/),
London). Accordingly, we defined ‘spare space’ as either roads on which
there is more than one lane in either direction or lane width above a
threshold (set at 10 m based on feedback from engineers and the
observation that South Road has a width of \~9 m yet can just fit
cycleways protected by plastic ‘wands’). This definition assumes no
alteration of the navigable network for motor vehicles.

To identify road sections with a spare lane we developed a simple
algorithm that takes the OSM variable
[`lanes`](https://wiki.openstreetmap.org/wiki/Key:lanes) if it is
present and, if not, derives the number from the highway type and
presence/absence of bus lanes. Width estimates were taken from the CyIPT
tool (see [www.cyipt.bike](https://www.cyipt.bike/) for details). All
segments defined as having a spare space using this method are shown in
Figure <a href="#fig:levels">3</a> (left).

## Attribute filtering and grouping

To ensure our route recommendations could achieve sufficient coherency,
we undertook several stages of road segment filtering and grouping.
Segments were grouped by road reference number (i.e. ‘A’ or ‘B’ road
number) and by proximing, within a 100 m buffer. Filtering then removed
groups without distance weighted mean width \>= 10 m or spare lanes
along the majority of their length, and groups with distance-weighted
mean cycling potential below a minimum threshold.
<!-- defined as one twenty-fifth of the 99th percentile segment level cycling potential within the city.  -->

Segments without a reference number were subjected to stricter filtering
criteria, to prevent the inclusion of unwanted short segments on side
streets.
<!-- Any of these segments that had cycling potential below 30 were excluded from the analysis.  -->
<!-- The segments were then grouped using a 20m buffer.  -->
<!-- Filtering followed the same criteria as for other roads, plus an additional filter to remove groups with length below 300 m. -->
For all segments, a final round of grouping (ignoring previous groups)
with a 100 m buffer was then used to remove groups with length below 500
m. This step removed short sections distant from any others, thus
improving the coherency of the results. Finally, road names were used to
identify continuous road sections with the same name of length \>= 500m.
Groups containing five or more different named roads were labeled
“Unnamed road.” An example of the impact of grouping strategy is shown
in Figure <a href="#fig:levels">3</a>.
<!-- Segments are grouped with a 100 m buffer, using the `igraph` R package; they are also filtered to exclude sections below a minimum length and cycling potential.  -->
<!-- The threshold length and cycling potential are adaptable depending on the nature of the region being studied and local cycling levels. -->
The resulting network shows that grouping the segments first then
filtering based on mean group-level attributes results in a more
cohesive network than filtering individual segments then grouping the
results.

<!-- Note this could be a function in an R package.. -->

<!-- see https://github.com/cyipt/cyipt/blob/82248b2f99e388fac314d34ec5aa49bb90a737a3/scripts/prep_data/clean_osm.R#L349 -->

<!-- reallocated road space in particular -->

<!-- An important distinction when developing methods for automated analysis of transport networks is the level of analysis. -->

<div class="figure">

<img src="article_files/figure-gfm/levels-1.png" alt="Illustration of the 'group then filter' method to identify roads with spare space that meet threshold values for length and cycling potential. The right hand panel contains roads on which the majority of segments have spare space (including segments that may not on their own be estimated to have spare space), coloured by group membership." width="100%" />

<p class="caption">

Figure 3: Illustration of the ‘group then filter’ method to identify
roads with spare space that meet threshold values for length and cycling
potential. The right hand panel contains roads on which the majority of
segments have spare space (including segments that may not on their own
be estimated to have spare space), coloured by group membership.

</p>

</div>

## Selection of top routes

Top routes were selected from the results of the previous steps. These
must not be labeled “Unnamed road” or have existing cycleways along more
than 80% of their length. A high threshold was chosen here because the
presence of an existing cycleway on OSM does not mean that this is
necessarily a high quality cycleway. Continuity of cycle provision is
important for creating high quality networks (Parkin 2018).

<!-- ## Scenarios and visualisation -->

<!-- To make the results more accessible and actionable we have made the results, discussed in the next section, publicly available at  -->

# FINDINGS

The results of the method applied to the city of Leeds are shown in
Figure <a href="#fig:res">4</a> (see
[cyipt.bike/rapid](https://www.cyipt.bike/rapid/west-yorkshire/) for
interactive version) and Table 2. We found that analysis of open
transport network data, alongside careful selection of parameters, can
generate plausible results for the prioritisation of pop-up cycle
infrastructure. Reducing tens of thousands of road segments Leeds down
to a handful of promising named road sections has great potential to
support policy-makers, especially when decisions need to be made fast.

<div class="figure">

<img src="figures/results-top-leeds.png" alt="Results of the Rapid Cycleway Prioritisation Tool, showing road segments with a spare lane (light blue) and road groups with a minium threshold length, 1km in this case (dark blue). The top 10 road groups are labelled." width="100%" />

<p class="caption">

Figure 4: Results of the Rapid Cycleway Prioritisation Tool, showing
road segments with a spare lane (light blue) and road groups with a
minium threshold length, 1km in this case (dark blue). The top 10 road
groups are labelled.

</p>

</div>

<table>

<caption>

Table 1: The top 10 candidate roads for space reallocation for pop-up
lane reallocation interventions. Roads with ‘spare lanes’ identified
using methods presented in the paper are ranked by cycling potential
under the Government Target scenario, representing a doubling in
commuter and school cycling levels compared with 2011 levels.

</caption>

<thead>

<tr>

<th style="text-align:left;">

Name

</th>

<th style="text-align:right;">

Length (m)

</th>

<th style="text-align:right;">

Potential (Government Target)

</th>

<th style="text-align:right;">

Km/day (length \* potential)

</th>

</tr>

</thead>

<tbody>

<tr>

<td style="text-align:left;">

Headingley Lane

</td>

<td style="text-align:right;">

971

</td>

<td style="text-align:right;">

546

</td>

<td style="text-align:right;">

530

</td>

</tr>

<tr>

<td style="text-align:left;">

A660

</td>

<td style="text-align:right;">

718

</td>

<td style="text-align:right;">

414

</td>

<td style="text-align:right;">

297

</td>

</tr>

<tr>

<td style="text-align:left;">

Woodhouse Lane

</td>

<td style="text-align:right;">

2438

</td>

<td style="text-align:right;">

372

</td>

<td style="text-align:right;">

907

</td>

</tr>

<tr>

<td style="text-align:left;">

A65

</td>

<td style="text-align:right;">

787

</td>

<td style="text-align:right;">

238

</td>

<td style="text-align:right;">

187

</td>

</tr>

<tr>

<td style="text-align:left;">

Kirkstall Road

</td>

<td style="text-align:right;">

4407

</td>

<td style="text-align:right;">

237

</td>

<td style="text-align:right;">

1044

</td>

</tr>

<tr>

<td style="text-align:left;">

Clay Pit Lane

</td>

<td style="text-align:right;">

2235

</td>

<td style="text-align:right;">

231

</td>

<td style="text-align:right;">

516

</td>

</tr>

<tr>

<td style="text-align:left;">

Low Road

</td>

<td style="text-align:right;">

516

</td>

<td style="text-align:right;">

194

</td>

<td style="text-align:right;">

100

</td>

</tr>

<tr>

<td style="text-align:left;">

Chapeltown Road

</td>

<td style="text-align:right;">

1744

</td>

<td style="text-align:right;">

163

</td>

<td style="text-align:right;">

284

</td>

</tr>

<tr>

<td style="text-align:left;">

Roundhay Road

</td>

<td style="text-align:right;">

909

</td>

<td style="text-align:right;">

161

</td>

<td style="text-align:right;">

146

</td>

</tr>

<tr>

<td style="text-align:left;">

Dewsbury Road

</td>

<td style="text-align:right;">

538

</td>

<td style="text-align:right;">

157

</td>

<td style="text-align:right;">

84

</td>

</tr>

</tbody>

</table>

After initially developing the method for a single city, we applied the
methods nationwide. An illustration of the scale of the results is shown
in Figure <a href="#fig:facet">5</a>, which shows the results for six
major cities in England, including existing cycleway and ‘cohesive
network’ layers, described on the tool’s website
[cyipt.bike/rapid](https://www.cyipt.bike/rapid/). Local authorities are
planning new pop-up cycleways informed by a range of sources of
evidence, including the Rapid Cycleway Prioritisation Tool, and in many
cases the plans match the routes highlighted by our tool.\[1\]

<div class="figure">

<img src="figures/facet-output.png" alt="Maps showing existing, disjointed cycleway networks (green), potential cycleway routes on wide roads according to the Rapid Cycleway Prioritisation Tool (blue) and cohesive networks (purple) in 6 major cities" width="100%" />

<p class="caption">

Figure 5: Maps showing existing, disjointed cycleway networks (green),
potential cycleway routes on wide roads according to the Rapid Cycleway
Prioritisation Tool (blue) and cohesive networks (purple) in 6 major
cities

</p>

</div>

The approach is not without limitations. Its reliance on data rather
than community engagement represents a rather top-down approach to
transport planning. The incorporation of our results into participatory
maps such as the one presented in Figure
<a href="#fig:commonplace">1</a> will help to mitigate this limitation.
Further work could also extend the method in various ways, for example
by refining estimates of cycling potential based on additional
parameters such as proximity to key destinations. We welcome feedback on
the results and methods at
[github.com/cyipt/popupCycleways](https://github.com/cyipt/popupCycleways).

A major advantage of the approach is that it is scalable. It would be
feasible to internationalise the approach, given sufficient computer and
developer resource to overcome the key data barriers: lack of cycling
potential and road width data.
<!-- Given the recent interest in and funding for pop-up cycleways, projects inspired by and building on the work presented in this paper, can help ensure that pop-up cycleway plans are evidence-based and effective, maximising the chances of them becoming permanent. -->
In summary, the methods presented can help lock-in the benefits of
COVID-19 related cycling booms long term.

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

<!-- There shall be no introduction, "road-map paragraph," literature review, conclusions, speculations, or  policy implications beyond what is included above. Focus on what you found, not why you found it. -->

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

<!-- Papers should be focused and to the point, and not begin with trite observations like "Congestion is a problem the world over." Usually you can delete your opening paragraph if it begins like that, and the reader is no worse off. As Strunk and White say: "Omit Needless Words". The Abstract should not say the same thing as the Introduction. -->

<!-- Transparency and Replicability -->

<!-- A minimum standard for a good paper is transparency and replicability: Can the reader understand what you did, and repeat it, and get the same answer? -->

<!-- Mathematical Conventions -->

<!-- Each variable shall have one, and only one, definition per document. -->

<!-- Each defined term in the document shall be represented by one and only one variable. -->

<!-- Lowercase and uppercase versions of the same letter should be logically related. For instance, use lowercase letters to define the PDF (probability distribution function) or individual instance, and uppercase letters the CDF (cumulative distribution function) or population, so when you sum:  i=1 to I, k=1 to K, etc. -->

<!-- All variables shall be a single letter or symbol. Double or triple letter variables can be confused with multiplication. If you have more than 52 symbols in your paper (26 letters for both lower and upper case), consider (a) there are too many, and (b) using Greek or Hebrew characters. -->

<!-- Use subscripts liberally to differentiate things that, for instance, are of a class but measured differently, or computed with different assumptions. -->

<!-- All equations shall have all of their variables defined. -->

<!-- Todo final bit -->

<!-- - check over the responses to reviewers -->

<!-- - double check and update the paper with new images from the tool  -->

# References

<div id="refs" class="references hanging-indent">

<div id="ref-aldred_cycling_2018">

Aldred, Rachel, Anna Goodman, John Gulliver, and James Woodcock. 2018.
“Cycling Injury Risk in London: A Case-Control Study Exploring the
Impact of Cycle Volumes, Motor Vehicle Volumes, and Road Characteristics
Including Speed Limits.” *Accident Analysis & Prevention* 117 (August):
75–84. <https://doi.org/10.1016/j.aap.2018.03.003>.

</div>

<div id="ref-chen_built_2016">

Chen, Peng, and Qing Shen. 2016. “Built Environment Effects on Cyclist
Injury Severity in Automobile-Involved Bicycle Crashes.” *Accident
Analysis & Prevention* 86: 239–46.

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

<div id="ref-jimenez-pavon_physical_2020">

Jim’enez-Pav’on, David, Ana Carbonell-Baeza, and Carl J. Lavie. 2020.
“Physical Exercise as Therapy to Fight Against the Mental and Physical
Consequences of COVID-19 Quarantine: Special Focus in Older People.”
*Progress in Cardiovascular Diseases*, March.
<https://doi.org/10.1016/j.pcad.2020.03.009>.

</div>

<div id="ref-jittrapirom_exploratory_2020">

Jittrapirom, Peraphan, and Garavig Tanaksaranond. 2020. “An Exploratory
Survey on the Perceived Risk of COVID-19 and Travelling.” Preprint.
SocArXiv. <https://doi.org/10.31235/osf.io/v3g5d>.

</div>

<div id="ref-laker_world_2020">

Laker, Laura. 2020. “World Cities Turn Their Streets over to Walkers and
Cyclists.” *The Guardian*, April.

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

<div id="ref-orsman_covid_2020">

Orsman, B. 2020. “Covid 19 Coronavirus: Social Distancing Cones Rolled
Out Across Auckland.” *NZ Herald*, April.

</div>

<div id="ref-parkin_designing_2018">

Parkin, John. 2018. *Designing for Cycle Traffic: International
Principles and Practice*. ICE Publishing.

</div>

<div id="ref-reid_government_2020">

Reid, Carlton. 2020. “U.K. Government Boosts Bicycling and Walking with
Ambitious Billion Post-Pandemic Plan.” *Forbes*.

</div>

<div id="ref-salfordcitycouncil_salford_2020">

Salford City Council. 2020. “Salford Liveable Streets.”
https://salfordliveablestreets.commonplace.is.

</div>

<div id="ref-tian_investigation_2020">

Tian, Huaiyu, Yonghong Liu, Yidan Li, Chieh-Hsi Wu, Bin Chen, Moritz U.
G. Kraemer, Bingying Li, et al. 2020. “An Investigation of Transmission
Control Measures During the First 50 Days of the COVID-19 Epidemic in
China.” *Science* 368 (6491): 638–42.
<https://doi.org/10.1126/science.abb6105>.

</div>

<div id="ref-transportscotland_10_2020">

Transport Scotland. 2020. “ Million to Support Pop-up Active Travel
Infrastructure.”
https://www.transport.gov.scot/news/10-million-to-support-pop-up-active-travel-infrastructure/.

</div>

</div>

1.   [Kirkstall
    Road](https://www.bbc.co.uk/news/uk-england-leeds-52577554) in Leeds
    and [Jamaica
    Road](https://www.se16.com/6208-work-starts-on-54m-cycleway-along-jamaica-road)
    in London are a couple of examples. Many more examples can be found
    on posts mentioning the tool on [social
    media](https://twitter.com/search?q=cyipt.bike%2Frapid).
