#pragma once
#inclib "sound"

#include once "SDL2/SDL.bi"
#include once "SDL2/SDL_mixer.bi"

declare sub Sound_Init (samplesPath as string = "", musicPath as string = "")
declare sub Sound_FreeSamples ()
declare sub Sound_Release ()
declare sub Sound_SetSamplesPath(path as string)
declare sub Sound_SetMusicPath(path as string)

declare sub Sound_LoadSample (id as integer, byval filename as string, volume as double=1.0, isRepeating as boolean=0, maxChannels as integer=4)
declare sub Sound_UpdateSample (id as integer, volume as double=-1, isRepeating as integer=-1, maxChannels as integer=-1)
declare sub Sound_UnloadSample (id as integer)
declare sub Sound_MuteSample
declare sub Sound_UnmuteSample
declare sub Sound_PlaySample (id as integer)
declare sub Sound_PauseSample (id as integer)
declare sub Sound_ResumeSample (id as integer)
declare sub Sound_PauseAllSamples ()
declare sub Sound_ResumeAllSamples  ()
declare sub Sound_StopSample (id as integer)
declare sub Sound_StopAllSamples ()

declare function Sound_GetMusicVolume() as double
declare function Sound_GetSamplesVolume() as double
declare sub Sound_SetMusicVolume(volume as double)
declare sub Sound_SetSamplesVolume(volume as double)

declare sub Sound_SetMusic (byval filename as string, isRepeating as integer = 1)
declare sub Sound_PlayMusic ()
declare sub Sound_StopMusic ()
declare sub Sound_PauseMusic ()
declare sub Sound_ResumeMusic ()
declare sub Sound_FadeInMusic (seconds as double = 3.0)
declare sub Sound_FadeOutMusic (seconds as double = 3.0)

declare function Sound_MusicIsFading () as integer
declare function Sound_MusicIsPlaying () as integer

declare sub      Sound_AddAliasForSampleFile(file as string, aka as string)
declare function Sound_GetSampleFileByAlias(aka as string) as string
declare sub      Sound_AddAliasForMusicFile(file as string, aka as string)
declare function Sound_GetMusicFileByAlias(aka as string) as string
