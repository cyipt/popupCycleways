
<!-- README.md is generated from README.Rmd. Please edit that file -->

# Data analysis to support temporary cycleways

<!-- badges: start -->

<!-- badges: end -->

The goal of this project is to flag roads on which there is

  - high cycling potential
  - road space that could be re-allocated

in the context of increased for demand for cycling to keyworker
workplaces.

It is based on an analysis of data generated for the Department for
Transport funded projects the Propensity to Cycle Tool (PCT) and the
Cycling Infrastructure Prioritisation Toolkit (CyIPT).

To overcome issues associated with doing this at a national level and
elicit feedback on the methods and preliminary results, we ran the
analysis on a sample of cities. We chose the top 5 in terms of absolute
long-term cycling potential (London, Birmingham, Manchester, Leeds,
Liverpool) plus an additional 5 cities that have active advocacy groups
(Newcastle, Sheffield, Cambridge, Bristol, Leicester). Estimates of
current and potential numbers who could cycle to work in these cities is
presented in the table below.
<!-- We did this by analysing data from the PCT project and selecting the top 10 cities in terms of long term cycling potential, plus Sheffield and Cambridge, : -->

| name       |     all | bicycle | dutch\_slc |
| :--------- | ------: | ------: | ---------: |
| London     | 3634280 |  155694 |     759755 |
| Birmingham |  392517 |    6476 |      76169 |
| Manchester |  199011 |    8447 |      54419 |
| Leeds      |  326680 |    6250 |      51046 |
| Liverpool  |  185117 |    3978 |      48306 |
| Bristol    |  192881 |   15797 |      37909 |
| Leicester  |  128501 |    4999 |      35253 |
| Sheffield  |  226477 |    4276 |      25973 |
| Newcastle  |  111295 |    3229 |      24792 |
| Cambridge  |   53295 |   17313 |      20056 |

Selection of 10 cities in England with high cycling potential or active
adovcacy groups. ‘All’ represents all commuters in the 2011 Census,
‘bicycle’ represents the number who cycled to work and ‘dutch\_slc’
the number who could cycle to work under a ‘Go Dutch’ scenario of
cycling uptake.

The geographic distribution of these cities is shown in the map below:

![](README_files/figure-gfm/unnamed-chunk-3-1.png)<!-- -->

These 12 study cities coincidentally represent almost exactly 1/4 of the
population in England. Welsh and Scottish cities with high cycling
potential such as Cardiff and Edinbugh were not included in the analysis
because the CyIPT does not currently have data outside of England,
although we could extend the methods to cover all UK cities at some
point.

Below we show the results for a selection of cities, with cycling
potential on the road network visualised under the ‘Government Target’
scenario, which represents a doubling in cycling compared with 2011
levels. London is close to meeting this target already.

We filtered-out roads with low levels of cycling potential and focus
only on roads that have at least one ‘spare lane’, defined as having
more than 1 lane in either direction. Roads that could be made oneway,
or that could be converted into ‘liveable streets’ by preventing through
traffic were not considered.

# London

![](README_files/figure-gfm/unnamed-chunk-4-1.png)<!-- -->

The top 10 roads:

![](README_files/figure-gfm/unnamed-chunk-5-1.png)<!-- -->

| name                 | ref   | road\_type | cycling\_potential | length\_m |
| :------------------- | :---- | :--------- | -----------------: | --------: |
| Kennington Park Road | A3    | trunk      |               3255 |       925 |
| Brixton Road         | A23   | trunk      |               2606 |      2849 |
| Stoke Newington Road | A10   | trunk      |               2501 |       590 |
| Talgarth Road        | A4    | trunk      |               2480 |      1454 |
| Camberwell New Road  | A202  | trunk      |               2420 |      1630 |
| Waterloo Bridge      | A301  | primary    |               2398 |      1166 |
| Theobalds Road       | A401  | primary    |               2267 |       565 |
| Whitechapel Road     | A11   | trunk      |               2111 |      1560 |
| Old Street           | A5201 | primary    |               2012 |       505 |
| West Cromwell Road   | A4    | trunk      |               1971 |      1024 |

# Leeds

![](README_files/figure-gfm/unnamed-chunk-6-1.png)<!-- -->

The top 10 roads:

![](README_files/figure-gfm/unnamed-chunk-7-1.png)<!-- -->

| name              | ref  | road\_type | cycling\_potential | length\_m |
| :---------------- | :--- | :--------- | -----------------: | --------: |
| Wellington Street |      | secondary  |                546 |      1027 |
| Willow Road       |      | tertiary   |                466 |       316 |
| Woodhouse Lane    | A660 | trunk      |                368 |      2373 |
| Blenheim Walk     | A660 | trunk      |                340 |       347 |
| Swinegate         |      | secondary  |                318 |       309 |
| Crown Point Road  | A653 | primary    |                316 |       652 |
| Kirkstall Road    | A65  | primary    |                261 |      3774 |
| Clay Pit Lane     | A58  | trunk      |                257 |      2163 |
| The Headrow       |      | tertiary   |                250 |       440 |
| Hunslet Road      | A639 | primary    |                221 |      1860 |

# Cambridge

![](README_files/figure-gfm/unnamed-chunk-8-1.png)<!-- -->

The top 10 roads:

![](README_files/figure-gfm/unnamed-chunk-9-1.png)<!-- -->

| name                  | ref   | road\_type  | cycling\_potential | length\_m |
| :-------------------- | :---- | :---------- | -----------------: | --------: |
| Saint Andrew’s Street |       | residential |               2449 |       164 |
| Hobson Street         |       | residential |               2393 |       216 |
| Hills Road            | A1307 | primary     |               1662 |       147 |
| Bridge Street         |       | residential |                878 |       194 |
| Elizabeth Way         | A1134 | primary     |                860 |       812 |
|                       | A1134 | primary     |                639 |       187 |
| Emmanuel Street       |       | residential |                586 |       151 |
| Chesterton Road       | A1134 | primary     |                530 |       194 |

# Bristol

![](README_files/figure-gfm/unnamed-chunk-10-1.png)<!-- -->

The top 10 roads:

![](README_files/figure-gfm/unnamed-chunk-11-1.png)<!-- -->

| name                | ref   | road\_type   | cycling\_potential | length\_m |
| :------------------ | :---- | :----------- | -----------------: | --------: |
| Temple Way          | A4044 | trunk        |                432 |       708 |
| Newfoundland Street | A4044 | trunk        |                255 |       496 |
| Bond Street South   | A4044 | trunk        |                246 |      1039 |
| Bedminster Parade   | A38   | trunk        |                234 |       401 |
| Bath Road           | A4    | trunk        |                191 |      6227 |
| Coronation Road     | A370  | trunk        |                179 |      2033 |
| Clarence Road       | A370  | trunk        |                124 |       666 |
| Malago Road         | A38   | trunk        |                123 |       478 |
| Hotwell Road        | A4    | primary      |                117 |       533 |
| East Street         |       | unclassified |                111 |       392 |
