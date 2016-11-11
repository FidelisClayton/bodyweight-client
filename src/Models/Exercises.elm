module Models.Exercises exposing (..)

import Json.Decode as Decode exposing ((:=))


type alias ExerciseId =
    Int


type alias Exercise =
    { id : ExerciseId
    , name : String
    , description : String
    , isHold : Bool
    , amazonIds : String
    , youtubeIds : String
    }


{-| Decode a single `Exercise` from the backend.
-}
exerciseDecoder : Decode.Decoder Exercise
exerciseDecoder =
    Decode.object6 Exercise
        ("id" := Decode.int)
        ("name" := Decode.string)
        ("description" := Decode.string)
        ("isHold" := Decode.bool)
        ("amazonIds" := Decode.string)
        ("youtubeIds" := Decode.string)


{-| Return a string representation of the type of Exercise(Reps or Hold).
-}
exerciseType : Exercise -> String
exerciseType { isHold } =
    if isHold then
        "Hold"
    else
        "Reps"
