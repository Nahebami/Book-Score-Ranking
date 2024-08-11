# Book-Score-Ranking

## Table of Contents
- [Project Overview](#project-overview)
- [Data Sources](#data-sources)
- [Tools](#tools)
- [Data Requirement Mapping](#data-requirement-mapping)
- [Data Process Flow](#data-process-flow)
- [Data Process Result](#data-process-result)
- [Data Result Consumption](#data-result-consumption)


### Project Overview
---
The goal of this project is to refine our current book ranking process by integrating a new set of parameter score to better prioritize and highlight books that are likely to be most valuable to our users. These scores are refreshed on a weekly basis to be pushed to a third party system to rank books to be resurfaced to the customers based on thier search criteria.


### Data Sources
---
1. Subscriber Revenue 
2. Subscriber Registration
3. Assigned Book Reading-list
4. Subscriber Reading Activity
5. Goggle SEO Pages
6. Book Catalogue



### Tools:
---
- AWS Step function
- AWS Athena
- Big Query
- Metabase & Power BI
- Excel
- Github



### Data Requirement Mapping:
---
<img width="1326" alt="image" src="https://github.com/user-attachments/assets/6f834e38-aa00-4f37-94ad-194ef45e13d8">


### Data Process Flow:
---
<img width="997" alt="image" src="https://github.com/user-attachments/assets/7bc35171-d643-4d25-974b-0b11e91f9b9e">


### Data Process Result:
---
After computing the final values for each parameter on all active books, the overall ranking is then applied based on the order of parameter preference which applies the tie breaking rule where neccessary to determine the overall ranking of a book. Find below a screenshot of the dashboard result.

<img width="1077" alt="image" src="https://github.com/user-attachments/assets/3967a496-c8b8-478f-bc60-626ed3e7d8d4">
<img width="1079" alt="image" src="https://github.com/user-attachments/assets/5228af2f-46f9-47de-b2f3-abfe944ae5d5">


### Data Result Consumption:
---
The process result is automated & frequently pushed to the thirdparty service.

