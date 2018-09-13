library(ggplot2) # Data visualization
library(gganimate)
library(readr) # CSV file I/O, e.g. the read_csv function
library(sqldf)

# Connecting to SQLite
driver <- dbDriver("SQLite")
conn <- dbConnect(driver,dbname="../input/database.sqlite")
# dbListTables(conn)
# Query to get the English Premier League standings from all seasons
query <- "select 
       m.season as season,t.team_long_name as team,
       SUM(case when (m.home_team_Api_id=t.team_api_id and m.home_team_goal-m.away_team_goal>=1) then 1 else 0 end) as HomeWins,
       SUM(case when (m.home_team_Api_id=t.team_api_id and m.home_team_goal=m.away_team_goal) then 1 else 0 end)  as HomeDraws,
       SUM(case when (m.home_team_Api_id=t.team_api_id and m.home_team_goal-m.away_team_goal<0) then 1 else 0 end) as HomeLoss,       
       SUM(case when (m.away_team_Api_id=t.team_api_id and m.away_team_goal-m.home_team_goal>=1) then 1 else 0 end) as AwayWins,
       SUM(case when (m.away_team_Api_id=t.team_api_id and m.home_team_goal=m.away_team_goal) then 1 else 0 end) as AwayDraws,       
       SUM(case when (m.away_team_Api_id=t.team_api_id and m.away_team_goal-m.home_team_goal<0) then 1 else 0 end) as AwayLoss,
       SUM(case when (m.home_team_Api_id=t.team_api_id and m.home_team_goal-m.away_team_goal>=1) then 1 else 0 end) 
     + SUM(case when (m.away_team_Api_id=t.team_api_id and m.away_team_goal-m.home_team_goal>=1) then 1 else 0 end)  as TotalWins,
       SUM(case when (m.home_team_Api_id=t.team_api_id and m.home_team_goal=m.away_team_goal) then 1 else 0 end) 
     + SUM(case when (m.away_team_Api_id=t.team_api_id and m.away_team_goal=m.home_team_goal) then 1 else 0 end)    as TotalDraws,
       SUM(case when (m.home_team_Api_id=t.team_api_id and m.home_team_goal-m.away_team_goal<0) then 1 else 0 end) 
     + SUM(case when (m.away_team_Api_id=t.team_api_id and m.away_team_goal-m.home_team_goal<0) then 1 else 0 end) as TotalLoss,
       SUM(case when (m.home_team_Api_id=t.team_api_id and m.home_team_goal-m.away_team_goal>=1) then 3 else 0 end) 
     + SUM(case when (m.away_team_Api_id=t.team_api_id and m.away_team_goal-m.home_team_goal>=1) then 3 else 0 end)                        
     + SUM(case when (m.home_team_Api_id=t.team_api_id and m.home_team_goal-m.away_team_goal=0) then 1 else 0 end) 
     + SUM(case when (m.away_team_Api_id=t.team_api_id and m.away_team_goal=m.home_team_goal) then 1 else 0 end) as TotalPoints,
       SUM(case when m.home_team_Api_id=t.team_api_id then m.home_team_goal end) as HomeGoals, 
       SUM(case when m.home_team_Api_id=t.team_api_id then m.away_team_goal end) as HomeGoalsconceded,
       SUM(case when m.away_team_Api_id=t.team_api_id then m.away_team_goal end) as AwayGoals,
       SUM(case when m.away_team_Api_id=t.team_api_id then m.home_team_goal end) as AwayGoalsconceded,    
       SUM(case when m.home_team_Api_id=t.team_api_id then m.home_team_goal end) 
     + SUM(case when m.away_team_Api_id=t.team_api_id then away_team_goal end) as TotalGoalsScored,
       SUM(case when m.home_team_Api_id=t.team_api_id then m.away_team_goal end) 
     + SUM(case when m.away_team_Api_id=t.team_api_id then home_team_goal end) as TotalGoalsConceded
from
    match m,team t
where 
    m.league_id='1729'
    and (t.team_api_id=m.home_team_api_id or t.team_api_id=m.away_team_api_id) 
group by m.season,t.team_long_name
order by m.season asc,TotalPoints desc "

res <- dbSendQuery(conn,query)
result<-dbFetch(res)
result_df <- data.frame(result)

# Table of English Premier League seasons sorted by Total Points scored

# Comparison of all teams in the English Premier league across seasons by Total Points Scored
ggplot(result_df,aes(TotalPoints,team,color=season)) + geom_point() + labs(x="Total Points Scored",y="Team",title="Points Scored vs Teams")

# Comparison of all teams across seasons by Total Points Scored
# Comparison of winners of English Premier League from all seasons
# Note: Teams which had the same points at the end of a season are tied as 
# champions,the winner is determined  by Goal Difference which is not done as a part of this exercise.

epl_winners <- aggregate(TotalPoints ~ season, data=result_df,max)
epl_league_winners <- merge(epl_winners,result_df)
# Table of English Premier League winners
epl_league_winners

ggplot(epl_league_winners,aes(team,TotalDraws,color=season)) + geom_point() + labs(x="Team",y="TotalDraws",title="Draws vs EPL champions")

# Query to get the League standings from all seasons across top 5 Leagues (England,Spain,Germnay,Italy,France)

query2 <-  " select 
       m.season as season,t.team_long_name as team,l.name as league,
       SUM(case when (m.home_team_Api_id=t.team_api_id and m.home_team_goal-m.away_team_goal>=1) then 1 else 0 end) as HomeWins,
       SUM(case when (m.home_team_Api_id=t.team_api_id and m.home_team_goal=m.away_team_goal) then 1 else 0 end)  as HomeDraws,
       SUM(case when (m.home_team_Api_id=t.team_api_id and m.home_team_goal-m.away_team_goal<0) then 1 else 0 end) as HomeLoss,       
       SUM(case when (m.away_team_Api_id=t.team_api_id and m.away_team_goal-m.home_team_goal>=1) then 1 else 0 end) as AwayWins,
       SUM(case when (m.away_team_Api_id=t.team_api_id and m.home_team_goal=m.away_team_goal) then 1 else 0 end) as AwayDraws,       
       SUM(case when (m.away_team_Api_id=t.team_api_id and m.away_team_goal-m.home_team_goal<0) then 1 else 0 end) as AwayLoss,
       SUM(case when (m.home_team_Api_id=t.team_api_id and m.home_team_goal-m.away_team_goal>=1) then 1 else 0 end) 
     + SUM(case when (m.away_team_Api_id=t.team_api_id and m.away_team_goal-m.home_team_goal>=1) then 1 else 0 end) as TotalWins,
       SUM(case when (m.home_team_Api_id=t.team_api_id and m.home_team_goal=m.away_team_goal) then 1 else 0 end) 
     + SUM(case when (m.away_team_Api_id=t.team_api_id and m.away_team_goal=m.home_team_goal) then 1 else 0 end) as TotalDraws,
       SUM(case when (m.home_team_Api_id=t.team_api_id and m.home_team_goal-m.away_team_goal<0) then 1 else 0 end) 
     + SUM(case when (m.away_team_Api_id=t.team_api_id and m.away_team_goal-m.home_team_goal<0) then 1 else 0 end) as TotalLoss,
       SUM(case when (m.home_team_Api_id=t.team_api_id and m.home_team_goal-m.away_team_goal>=1) then 3 else 0 end) 
     + SUM(case when (m.away_team_Api_id=t.team_api_id and m.away_team_goal-m.home_team_goal>=1) then 3 else 0 end)                        
     + SUM(case when (m.home_team_Api_id=t.team_api_id and m.home_team_goal-m.away_team_goal=0) then 1 else 0 end) 
     + SUM(case when (m.away_team_Api_id=t.team_api_id and m.away_team_goal=m.home_team_goal) then 1 else 0 end) as TotalPoints,
       SUM(case when m.home_team_Api_id=t.team_api_id then m.home_team_goal end) as HomeGoals, 
       SUM(case when m.home_team_Api_id=t.team_api_id then m.away_team_goal end) as HomeGoalsconceded,
       SUM(case when m.away_team_Api_id=t.team_api_id then m.away_team_goal end) as AwayGoals,
       SUM(case when m.away_team_Api_id=t.team_api_id then m.home_team_goal end) as AwayGoalsconceded,    
       SUM(case when m.home_team_Api_id=t.team_api_id then m.home_team_goal end) 
     + SUM(case when m.away_team_Api_id=t.team_api_id then away_team_goal end) as TotalGoalsScored,
       SUM(case when m.home_team_Api_id=t.team_api_id then m.away_team_goal end) 
     + SUM(case when m.away_team_Api_id=t.team_api_id then home_team_goal end) as TotalGoalsConceded
from
    match m,team t,league l
where 
    m.league_id in ('1729','4769','7809','10257','21518')
    and (t.team_api_id=m.home_team_api_id or t.team_api_id=m.away_team_api_id) 
    and l.id=m.league_id
group by l.name,m.season,t.team_long_name
order by l.name,m.season asc,TotalPoints desc"

sol <- dbSendQuery(conn,query2)
solution <- dbFetch(sol,n=-1)
solution_df <- data.frame(solution)

# Comparison of winners of top 5 Leagues from all seasons
# Note: Teams which had the same points at the end of a season are tied as 
# champions,the winner determined by Goal Difference,is not done as a part of this exercise.

# League winners from top 5 leagues by season
# euro_s_winners <- aggregate(TotalPoints ~ season + league, data=solution_df,max)
# euro_season_winners <- merge(euro_winners,solution_df)

# League winners from top 5 leagues by League
euro_l_winners <- aggregate(TotalPoints ~ league + season, data=solution_df,max)
euro_league_winners <- merge(euro_l_winners,solution_df)

# Goals conceded per season by winning teams across leagues
ggplot(euro_league_winners,aes(season,TotalGoalsConceded,color=team)) + geom_point() + geom_count(col="tomato3", show.legend=F) + labs(x="Season",y="Goals Conceded",title="Goals Conceded by season")

# Home Wins by winning teams across leagues
ggplot(euro_league_winners,aes(league,team,color=HomeWins,size=HomeGoals)) + geom_point() + labs(x="League",y="Team",title="Home Wins by teams")







