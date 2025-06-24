import { DateTime } from 'luxon';

function paddedNumber(input:number):string {
  return input.toString().padStart(2, '0');
}

export function formatElapsedTime(startTime:string):string {
  const start = DateTime.fromISO(startTime);
  const now = DateTime.now();
  const duration = now.diff(start, 'seconds').seconds;

  const hours = Math.floor(duration / 3600);
  const minutes = Math.floor((duration - (hours * 3600)) / 60);
  const seconds = duration - (hours * 3600) - (minutes * 60);

  return [
    paddedNumber(hours),
    paddedNumber(minutes),
    paddedNumber(seconds),
  ].join(':');
}
