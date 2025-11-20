# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     SubjectManager.Repo.insert!(%SubjectManager.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias SubjectManager.Repo
alias SubjectManager.Subjects.Subject

%Subject{
  name: "Lionel Messi",
  team: "Inter Miami CF",
  bio: """
  Lionel Messi is an Argentine professional footballer who plays as a forward for Inter Miami CF and the Argentina national team. Widely regarded as one of the greatest players of all time, Messi has won a record eight Ballon d'Or awards and has scored over 850 career goals. In July 2023, he joined Inter Miami CF in Major League Soccer, leading the team to its first-ever trophy by winning the Leagues Cup.
  """,
  position: :forward,
  image_path: "/images/lionel-messi.jpg"
}
|> Repo.insert!()

%Subject{
  name: "Luis Suárez",
  team: "Inter Miami CF",
  bio: """
  Luis Suárez is a Uruguayan professional footballer who plays as a striker for Inter Miami CF. Known for his clinical finishing and tenacity, Suárez has been a prolific scorer throughout his career, playing for clubs like Liverpool, FC Barcelona, and Atlético Madrid. In December 2023, he joined Inter Miami CF, reuniting with former teammate Lionel Messi. Suárez announced his retirement from international football in September 2024, concluding a 17-year career with the Uruguay national team.
  """,
  position: :forward,
  image_path: "/images/luis-suarez.jpg"
}
|> Repo.insert!()

%Subject{
  name: "Edinson Cavani",
  team: "Boca Juniors",
  bio: """
  Edinson Cavani is a Uruguayan professional footballer who plays as a forward for Boca Juniors. Renowned for his exceptional goal-scoring ability and work rate, Cavani has had successful stints with clubs like Napoli, Paris Saint-Germain, and Manchester United. In July 2023, he joined Boca Juniors, where he has continued to be a key player. Cavani retired from international football in May 2024, ending a distinguished career with the Uruguay national team.
  """,
  position: :forward,
  image_path: "/images/edinson-cavani.jpg"
}
|> Repo.insert!()

%Subject{
  name: "Darwin Núñez",
  team: "Liverpool FC",
  bio: """
  Darwin Núñez is a Uruguayan professional footballer who plays as a forward for Liverpool FC. Known for his pace, strength, and goal-scoring prowess, Núñez has quickly established himself as a key player for both club and country. Since joining Liverpool in 2022, he has been instrumental in their attacking lineup, contributing significantly in both domestic and European competitions.
  """,
  position: :forward,
  image_path: "/images/darwin-nunez.jpg"
}
|> Repo.insert!()

%Subject{
  name: "Julián Álvarez",
  team: "Manchester City",
  bio: """
  Julián Álvarez is an Argentine professional footballer who plays as a forward for Manchester City. Celebrated for his versatility and sharp finishing, Álvarez joined Manchester City in January 2022. He played a pivotal role in the team's successes, including their treble-winning 2022–23 season, and has continued to be an influential figure in their attacking lineup.
  """,
  position: :forward,
  image_path: "/images/julian-alvarez.jpg"
}
|> Repo.insert!()

%Subject{
  name: "Paulo Dybala",
  team: "AS Roma",
  bio: """
  Paulo Dybala is an Argentine professional footballer who plays as a forward for AS Roma. Known for his creativity, dribbling skills, and goal-scoring ability, Dybala joined Roma in July 2022. He has been a crucial player for the team, contributing significantly in both domestic league matches and European competitions.
  """,
  position: :forward,
  image_path: "/images/paulo-dybala.jpg"
}
|> Repo.insert!()

%Subject{
  name: "Lautaro Martínez",
  team: "Inter Milan",
  bio: """
  Lautaro Martínez is an Argentine professional footballer who plays as a striker for Inter Milan. Recognized for his strength, technical ability, and goal-scoring talent, Martínez has been a vital part of Inter Milan's attacking force since joining the club in 2018. He has contributed to the team's successes in both domestic and European competitions.
  """,
  position: :forward,
  image_path: "/images/lautaro-martinez.jpg"
}
|> Repo.insert!()

%Subject{
  name: "Giovani Lo Celso",
  team: "Tottenham Hotspur",
  bio: """
  Giovani Lo Celso is an Argentine professional footballer who plays as a midfielder for Tottenham Hotspur. Valued for his vision, passing accuracy, and versatility, Lo Celso has been an important player for Tottenham since joining the club in 2019. He has also been a consistent performer for the Argentina national team.
  """,
  position: :midfielder,
  image_path: "/images/giovani-lo-celso.jpg"
}
|> Repo.insert!()

%Subject{
  name: "Diego Forlán",
  team: "Retired",
  bio: """
  Diego Forlán is a retired Uruguayan professional footballer who played as a forward. Renowned for his powerful shooting and technical skills, Forlán had a distinguished career, playing for clubs like Manchester United, Villarreal, and Atlético Madrid. He was awarded the Golden Ball at the 2010 FIFA World Cup as the tournament's best player. Forlán retired from professional football in 2019.
  """,
  position: :forward,
  image_path: "/images/diego-forlan.jpg"
}
|> Repo.insert!()

%Subject{
  name: "Brian Rodríguez",
  team: "Club América",
  bio: """
  Brian Rodríguez is a Uruguayan professional footballer who plays as a winger for Club América. Known for his speed and dribbling skills, Rodríguez has been an asset to Club América since joining the team. He has also represented the Uruguay national team, contributing to their attacking options.
  """,
  position: :winger,
  image_path: "/images/brian-rodriguez.jpg"
}
|> Repo.insert!()

%Subject{
  name: "Diego Godín",
  team: "Retired",
  bio: """
  Diego Godín is a legendary Uruguayan former footballer who played as a central defender. Renowned for his leadership, aerial ability, and defensive intelligence, Godín was the heart of Uruguay’s defense for over a decade. He captained Atlético Madrid to numerous victories, including their La Liga title in 2014. As Uruguay’s all-time leader in appearances, he played a vital role in their 2011 Copa América triumph. Godín announced his retirement from professional football in 2023, leaving behind a legacy as one of the greatest defenders in South American football.
  """,
  position: :defender,
  image_path: "/images/diego-godin.jpg"
}
|> Repo.insert!()

%Subject{
  name: "Emiliano Martínez",
  team: "Aston Villa",
  bio: """
  Emiliano "Dibu" Martínez is an Argentine professional footballer who plays as a goalkeeper for Aston Villa and the Argentina national team. A fan favorite, Martínez became a national hero after his heroic performances in penalty shootouts during Argentina's victories in the 2021 Copa América and the 2022 FIFA World Cup. His crucial saves, leadership, and fiery personality have made him one of the most beloved goalkeepers in Argentina’s history. Martínez continues to be a key player for both club and country.
  """,
  position: :goalkeeper,
  image_path: "/images/emiliano-martinez.jpg"
}
|> Repo.insert!()
