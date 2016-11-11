module Commands exposing (..)

import HttpBuilder exposing (send, stringReader, jsonReader, get, post, withHeader, withJsonBody)
import Json.Decode as Decode exposing ((:=))
import Json.Encode as Encode
import Messages exposing (Msg(..), HttpMsg)
import Models.Exercises exposing (Exercise, ExerciseId, exerciseDecoder, exerciseEncoder)
import Routing exposing (Route(..))
import Task


{-| Return a command that fetches any relevant data for the Route.
-}
fetchForRoute : Route -> Cmd Msg
fetchForRoute route =
    case route of
        HomeRoute ->
            Cmd.none

        ExercisesRoute ->
            fetchExercises

        ExerciseAddRoute ->
            Cmd.none

        ExerciseRoute id ->
            fetchExercise id

        NotFoundRoute ->
            Cmd.none


{-| Fetch data from the backend server.
-}
fetch : String -> Decode.Decoder a -> (HttpMsg a -> msg) -> Cmd msg
fetch url decoder msg =
    get ("/api/" ++ url)
        |> send (jsonReader decoder) stringReader
        |> Task.perform (msg << Err) (msg << Ok << .data)


{-| Fetch all the Exercises.
-}
fetchExercises : Cmd Msg
fetchExercises =
    fetch "exercises" ("exercise" := Decode.list exerciseDecoder) FetchExercises


{-| Fetch a single Exercise.
-}
fetchExercise : ExerciseId -> Cmd Msg
fetchExercise id =
    fetch ("exercises/" ++ toString id) ("exercise" := exerciseDecoder) FetchExercise


{-| Create an Exercise.
-}
createExercise : Exercise -> Cmd Msg
createExercise exercise =
    post ("/api/exercises/")
        |> withHeader "Content-Type" "application/json"
        |> withJsonBody (Encode.object [ ( "exercise", exerciseEncoder exercise ) ])
        |> send (jsonReader ("exercise" := exerciseDecoder)) stringReader
        |> Task.perform (CreateExercise << Err) (CreateExercise << Ok << .data)
